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
  def self.import(force: false)
    PackagesInventoriesImporter.new.import(force: force)
  end

  # --- Prints out messages
  def output(msg)
    pp(msg) unless Rails.env.test?
  end

  # --- Prompts the user to connfirm an action before running it
  def confirm(msg)
    STDOUT.puts(msg)
    raise CANCELLED unless STDIN.gets.chomp.eql?('yes')
    yield
  end

  # --- Asserts we're not overriding any data before runninng
  def prepare(force: false)
    if PackagesInventory.count.positive?
      raise ALREADY_RAN_MSG unless force
      confirm(FORCE_CONFIRMATION_MSG) { Package.destroy_all }
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
    bar = RakeProgressbar.new(count) unless Rails.env.test?
    begin
      Package.find_each do |package|
        yield(package)
        bar.inc  unless Rails.env.test?
      end
    ensure
      bar.finished  unless Rails.env.test?
    end
  end

  # --- Main import method
  #
  # Will first run a sanity check before proceeding with the actual import
  #
  def import(force: false, rehearsal: true)
    importing = !rehearsal
    @errors = []

    # -- Pre-import checks
    prepare(force: force)

    output('---> REHEARSING') if rehearsal
    output('---> IMPORTING')  if importing

    # -- Import loop
    each_package do |package|
      verify_package(package) if rehearsal
      import_package(package) if importing
    end

    if rehearsal
      if failed?
        output(@errors)
        raise REHEARSAL_FAILURE
      end

      # -- Run import after rehearsal
      import(rehearsal: false)
    else
      output(COMPLETED)
    end
  end

  # --- Returns the 'most appropriate' location for a package
  def inventory_location(package)
    loc = package.locations.first
    return loc unless (loc.nil? || loc.dispatch?)
    package.package_type.location
  end

  # --- Returns the time at which a package was inventorized
  def inventory_time(package)
    package.received_at || package.created_at
  end

  # --- Returns the time at which the package was dispatched
  def dispatch_time(package)
    pkg_loc = package.packages_locations.first
    return pkg_loc.updated_at if pkg_loc.location.dispatch? # --- Dispatch pkg_location creation
    package.stockit_sent_on # --- Fallback
  end

  def is_dispatched?(package)
    package.quantity.zero?
  end

  # --- Adds the necessary rows to the inventory for a package
  def import_package(package)
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
    @errors.push(MULTIPLE_LOCATIONS_ERR % [package.id]) if package.locations.length > 1
    @errors.push(NO_LOCATION_ERR % [package.id]) if package.locations.length.zero?
    @errors.push(INVALID_QUANTITY % [package.id, package.quantity]) if package.quantity.negative?
    if is_dispatched?(package)
      @errors.push(MISSING_ORDERS_PACKAGE % [package.id]) if package.orders_packages.count.zero?
    end
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

  MULTIPLE_LOCATIONS_ERR = '[Err] Package (%s) has multiple locations'
  NO_LOCATION_ERR = '[Err] Package (%s) has no location'
  INVALID_QUANTITY = '[Err] Package (%s) has an invalid quantity of %s'
  MISSING_ORDERS_PACKAGE = '[Err] Package (%s) looks dispatched, but has no orders_package'
end
