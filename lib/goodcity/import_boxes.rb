#
# STEPS TO RUN
# 1. Run the following SQL on Stockit and export the data to {Rails.root}/tmp/import_boxes.csv
#    IMPORTANT: we expect the first row in the CSV file to be a header row
#
#    SELECT boxes.box_number, items.inventory_number, boxes.description, boxes.comments,
#     packages.length, packages.width, packages.height, packages.weight
#    FROM boxes
#    LEFT JOIN items on items.box_id=boxes.id
#    WHERE items.sent_on is NULL
#        AND items.quantity != 0
#    ORDER BY boxes.box_number, items.inventory_number
#
# 2. Run a GoodCity rails console connected to the production environment
#    > require 'goodcity/import_boxes'
#    > current_user = User.find(id)
#    > GoodCity::ImportBoxes.new(current_user).run!
#
# WHAT THIS SCRIPT DOES
# The SQL generates a list of IN STOCK items that are in Stockit boxes. For convenience, each row corresponds to 1 item in 1 box.
# Since a box can contain many items, there will be many rows with the same box details where each item inventory_number is different.
# The script runs through the csv, generating the box the first time it encounters it and then packing the items in the box.
# If an error is encountered, the script will log it and continue on to the next row. We plan to deal with the errata once the import is complete.
# This script is designed to be run many times with the data set and if an item is already in the box, it will skip and carry on.

# Questions: what about boxes on a pallet?

module Goodcity
  class ImportBoxes

    STATUS_FAIL     = 'fail'
    STATUS_SUCCESS  = 'success'
    CSV_LOG_HEADER  = ["box_number", "inventory_number", "status", "log_comment"]

    def initialize(user)
      @import_boxes_csv_file_path = File.join(Rails.root, 'tmp', 'import_boxes.csv')
      @log_file_path              = File.join(Rails.root, 'log', 'import_boxes.log')
      @log                        = []
      @user                       = user
      User.current_user           = user # for PaperTrail / Versions
    end

    def run!
      CSV.foreach(@import_boxes_csv_file_path, headers: true) do |row|
        puts "Putting package #{row["inventory_number"]} in box #{box_number}"
        import_row(row)
      end
      write_log_file
      puts "Please review the log #{@log_file_path} for any errors."
    end

    def import_row!(row)
      validate_key_fields!(row)

      SettingsValidator.bypass do
        package   = find_package!(row)
        box       = create_box(row, package)

        pack_package_in_box(box, package)

        box
      end
    end

    def import_row(row)
      return unless validate_key_fields!(row)

      ActiveRecord::Base.transaction do
        begin
          import_box!(row)
          log_entry(row, STATUS_SUCCESS, "Package #{row["inventory_number"]} is in box #{row["box_number"]}")
        rescue Exception => ex
          # This may create a rod for our backs... 
          #   capture error, log it, rollback and carry on
          log_entry(row, STATUS_FAIL, ex.message)
          raise ActiveRecord::Rollback
        end
      end
    end

    private

    # If box doesn't exist, create a package with a box package_type and inventorize it
    def create_box(row, package)
      # Stockit boxes get their internal details from the first item in the box so we make the same assumption here.
      box = Package.where(inventory_number: row["box_number"]).first
      if !box.present?
        box = Package.new(
          storage_type_id:    storage_type_box.id,
          donor_condition_id: package.donor_condition_id,
          inventory_number:   row["box_number"],
          package_type:       package.package_type, # what if this package_type doesn't have "allow_box" set?
          received_quantity:  1,
          grade:              package.grade,
          notes:              row["description"],
          comment:            row["comments"],
          length:             row["length"],
          width:              row["width"],
          height:             row["height"],
          weight:             row["weight"]
        )
        box.save!
        Package::Operations.inventorize(box, package.locations.first.id) unless PackagesInventory.inventorized?(box)
      end
      box
    end

    # The package must pre-exist in GoodCity
    def find_package!(row)
      code    = row["inventory_number"]
      package = Package.find_by(inventory_number: code)

      raise Goodcity::NotFoundError.with_text("Package with inventory number '#{code}' was not found") if package.blank?

      package
    end

    # If the package isn't already in the box
    # Note we assume (correctly) that the full quantity of the item goes in the box and
    #   that there is only have one location because this is a Stockit item.
    def pack_package_in_box(box, package)
      return if PackagesInventory.packages_contained_in(box).include?(package) # already in there ;)

      location_id = package.locations.first.id
      quantity    = package.received_quantity

      Package::Operations.pack_or_unpack(container: box, package: package, location_id: location_id, quantity: quantity, user_id: @user.id, task: "pack!", strict: false)
    end

    def storage_type_box
      @storage_type_box ||= StorageType.find_by_name("Box")
    end

    def validate_key_fields!(row)
      raise Goodcity::InvalidParamsError.with_text('Missing box_number')        if row["box_number"].blank?
      raise Goodcity::InvalidParamsError.with_text('Missing inventory_number')  if row["inventory_number"].blank?
    end

    def log_entry(row, status, log_comment)
      box_number = row["box_number"]
      inventory_number = row["inventory_number"]
      @log << [box_number, inventory_number, status, log_comment]
      puts [box_number, inventory_number, status, log_comment].join(", ")
    end

    def write_log_file
      return if Rails.env.test?
      CSV.open(@log_file_path, "wb") do |csv|
        csv << CSV_HEADER
        @log.each do |row|
          csv << row
        end
      end
    end
  end
end
