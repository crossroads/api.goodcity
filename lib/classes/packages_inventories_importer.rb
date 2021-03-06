require 'csv'

# PackagesInventoriesImporter
#
# @description Initializes the packages inventory from the existing packages
#
# Usage :
#   PackagesInventoriesImporter.import(force: false|true)
#
class PackagesInventoriesImporter
  TABLE_NAME = 'packages_inventories'

  Actions = PackagesInventory::Actions

  # --- Entry point
  def self.import(force: false, rehearsal: false)
    PackagesInventoriesImporter.new.import(force: force, rehearsal: rehearsal)
  end

  # --- Prints out messages
  def output(msg)
    pp(msg) unless Rails.env.test?
  end

  # --- Prompts the user to connfirm an action before running it
  def confirm(msg)
    unless Rails.env.test?
      STDOUT.puts(msg)
      raise CANCELLED unless STDIN.gets.chomp.eql?('yes')
    end
    yield
  end

  # --- Asserts we're not overriding any data before runninng
  def prepare(force: false)
    if PackagesInventory.count.positive?
      raise ALREADY_RAN_MSG unless force
      confirm(FORCE_CONFIRMATION_MSG) do
        ActiveRecord::Base.connection.execute('DELETE FROM packages_inventories')
      end
    end
  end

  # --- Returns a system user to use as author of each row
  def import_author
    # We use the oldest available system user
    @user ||= User.system_user
    @user
  end

  # --- Returns true if there are errors
  def failed?
    @errors.length.positive?
  end

  # --- Loops over each package in the database
  def each_package
    count = Package.count
    bar = Progressbar.new(count)
    begin
      Package.find_each do |package|
        yield(package)
        bar.inc
      end
    ensure
      bar.finished
    end
  end

  def rehearse
    @errors = []

    output('---> REHEARSING')

    each_package { |package| verify_package(package) }
    if failed?
      write_csv("packages_inventory_import_errors", error_headers, @errors)
      raise REHEARSAL_FAILURE
    else
      output('--> Rehearsal completed with no errors');
    end
  end

  # --- Main import method
  #
  # Will first run a sanity check before proceeding with the actual import
  #
  def import(force: false, rehearsal: true)
    return rehearse if rehearsal

    # -- Pre-import checks
    prepare(force: force)

    # -- Import
    output('---> IMPORTING')
    each_package { |package| import_package(package) }

    output(COMPLETED)
  end

  # --- Returns the 'most appropriate' location for a package
  def fallback_location
    @fallback_location ||= Location.find_by(area: 'Incoming') || Location.first
    @fallback_location
  end

  def inventory_location(package)
    package.locations.first || package.package_type.location || fallback_location
  end

  # --- Returns the time at which a package was inventorized
  def inventory_time(package)
    package.received_at || package.created_at
  end

  # --- Returns the time at which the package was dispatched
  def dispatch_time(package)
    return package.stockit_sent_on if package.stockit_sent_on.present?
    dispatched_op = package.orders_packages.dispatched.first
    dispatched_op&.sent_on || dispatched_op&.updated_at
  end

  def is_dispatched?(package)
    dispatch_time(package).present?
  end

  # --- Adds the necessary rows to the inventory for a package
  def import_package(package)
    return if package.inventory_number.blank?

    insert_row(package: package, action: Actions::INVENTORY, time: inventory_time(package), quantity: package.received_quantity)

    if is_dispatched?(package)
      source = package.orders_packages.first
      insert_row(
        package: package,
        action: Actions::DISPATCH,
        time: dispatch_time(package),
        quantity: -1 * package.received_quantity,
        source: source
      )
    end
  end

  # --- Sanity checks
  def verify_package(package)
    on_error(package, MULTIPLE_LOCATIONS_ERR % [package.id]) if package.locations.length > 1
    on_error(package, UNINVENTORIZED_WITH_LOCATION % [package.id]) if package.inventory_number.blank? && package.locations.count.positive?
    if is_dispatched?(package)
      on_error(package, MISSING_ORDERS_PACKAGE % [package.id]) if package.orders_packages.count.zero?
    elsif package.inventory_number.present?
      on_error(package, NO_LOCATION_ERR % [package.id]) if package.locations.length.zero?
      on_error(package, BAD_PACKAGES_LOCATION_QUANTITY % [package.id]) if package.packages_locations.first.quantity != package.received_quantity
    end
  end

  def error_headers
    ['package_id', 'locations', 'error']
  end

  def on_error(package, msg)
    @errors.push([
      package.id.to_s,
      package.packages_locations
        .map { |pl| "#{pl&.location&.display_name}(#{pl.quantity})" }.join(" "),
      msg
    ])
  end

  # --- SQL friendly string
  def str(v)
    "'#{v}'"
  end

  # --- SQL to insert a row into the inventory
  def insert_row(package:, action:, time:, quantity:, source: nil)
    location = inventory_location(package)
    columns = [
      'package_id', 'location_id', 'user_id',
      'action', 'quantity',
      'source_type', 'source_id',
      'created_at', 'updated_at'
    ]

    source_type = source.present? ? str(source.class.name) : 'NULL'
    source_id = source.present? ? source.id : 'NULL'
    values = [
      package.id, location.id, import_author.id,
      str(action), quantity,
      source_type, source_id,
      str(time.to_s(:db)),
      str(time.to_s(:db))
    ]

    # We use SQL directly to avoid ORM hooks from firing. Also allows us to set timestamps manually
    ActiveRecord::Base.connection.execute <<-SQL
      INSERT INTO #{TABLE_NAME}
        (#{columns.join(', ')})
      VALUES (#{values.join(", ")})
    SQL
  end

  # --- Small wrapper around the progress bar in order to disable it in tests
  class Progressbar
    def initialize(count)
      @bar = RakeProgressbar.new(count) unless Rails.env.test?
    end

    def inc
      @bar.inc unless Rails.env.test?
    end

    def finished
      @bar.finished unless Rails.env.test?
    end
  end

  # file_name: name of file to place in Rails_root/tmp/ folder
  # header: array of header columns [ col1, col2 ]
  # contents: 2D array of data [ [row1col1, row1col2], [row2col1, row2col2] ]
  def write_csv(file_name, headers, contents)
    return if Rails.env.test?
    file_path = File.join(Rails.application.root, "tmp", "#{Rails.env}.#{file_name}.csv")
    CSV.open(file_path, "wb") do |csv|
      csv << headers
      contents.each do |row|
        csv << row
      end
    end
    output("CSV OUTPUT >>> #{file_path}")
  end

  # --- ERROR MESSAGES

  CANCELLED = 'Import cancelled by user'

  COMPLETED = 'Import Completed'

  REHEARSAL_FAILURE = <<-TEXT
    Some erroneous data was detected during rehearsal
  TEXT

  ALREADY_RAN_MSG = <<-TEXT
    Pre-existing packages_inventory records, cannot import.
    Import can be run with the flag force=true to rebuild the table from scratch
  TEXT

  FORCE_CONFIRMATION_MSG = <<-TEXT
    Runninng the import with force=true will cause a deletion of existing table.
    Please type 'yes' to proceed
  TEXT

  BAD_PACKAGES_LOCATION_QUANTITY = '[Err] Package (%s) doesnt look dispatched but the packages_location quantity doesnt match the received qty'.freeze
  UNINVENTORIZED_WITH_LOCATION = '[Err] Package (%s) is not inventorized but has packages_locations'.freeze
  MULTIPLE_LOCATIONS_ERR = '[Err] Package (%s) has multiple locations'.freeze
  NO_LOCATION_ERR = '[Err] Package (%s) doesnt look dispatched but has no location'.freeze
  INVALID_QUANTITY = '[Err] Package (%s) has an invalid quantity of %s'.freeze
  MISSING_ORDERS_PACKAGE = '[Err] Package (%s) looks dispatched, but has no orders_package'.freeze
end