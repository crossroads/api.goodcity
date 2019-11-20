#
# For a given inventory_number, this will
#   - delete all packages with that number and their associated package_locations,
#     orders_packages, images, requested_packages and inventory_number  
#   - request updated information from Stockit to recreate a good package
# Note: destroy and delete have significant differences here.
#   - destroy will remove a row from the database and run callbacks to update stockit
#     and other parts of the system
#   - delete will remove the row from the database but avoid running any other callbacks
# Usage:
#   require 'goodcity/package_safe_delete'
#   Goodcity::PackageSafeDelete.new('123245').run
#   Goodcity::PackageSafeDelete.new(['111111', '222222']).run

require 'csv'

module Goodcity
  class PackageSafeDelete

    def initialize(inventory_numbers)
      @inventory_numbers = [inventory_numbers].flatten.uniq
      @csv_log = []
    end

    def run
      @packages = Package.where(inventory_number: @inventory_numbers).order(:inventory_number)
      @packages.find_each do |package|
        destroy_package(package) if ok_to_destroy?(package)
      end
      write_csv("package_delete_#{Rails.env}.csv", ['inventory_number', 'message'], @csv_log)
    end

    private

    # Is it ok to destroy the package
    def ok_to_destroy?(package)
      if package.item_id.present?
        log(package, "NOT OK to destroy. Package #{package.id} belongs to an Item")
        return false
      end
      return true
    end

    # Destroy the package without callbacks because we don't want Stockit to delete it's records
    #  - deletes the image on Cloudinary (unless it is referenced by another package)
    #  - deletes orders_package but doesn't send destroy job to Stockit
    #  - removes package from users cart, this will send a push update
    #  - removes inventory number from Inventory table
    def destroy_package(package)
      package.packages_locations.each do |pl|
        log(package, "Destroying package_location #{pl.location.try(:label)}")
        pl.destroy
      end
      package.images.each do |i|
        log(package, "Destroying image #{i.id}")
        i.destroy
      end
      package.orders_packages.each do |op|
        log(package, "Deleting orders_package #{op.order.try(:code)}")
        op.delete
      end
      package.requested_packages.each do |rp|
        log(package, "Destroying requested_package #{rp.id}")
        rp.destroy
      end
      inventory_number = package.inventory_number
      log(package, "Destroying package #{package.id}")
      package.reload.destroy
      destroy_inventory_number(inventory_number) # must come after package.destroy
    end

    # remove the GC inventory number if there isn't another package with the same number
    # (should never be the case but we have come across it)
    def destroy_inventory_number(inventory_number)
      return if inventory_number.blank?
      return unless inventory_number.match(/^[0-9]+$/) # A GC number
      if !Package.where(inventory_number: inventory_number).exists?
        InventoryNumber.find_by(code: inventory_number).try(:destroy)
        log(inventory_number, "Deleting inventory_number from InventoryNumber table")
      end
    end

    def log(package, message)
      inventory_number = package.try(:inventory_number) || package
      pp "#{inventory_number} : #{message}" unless Rails.env.test?
      @csv_log << [inventory_number, message]
    end

    # file_name: name of file to place in Rails_root/tmp/ folder
    # header: array of header columns [ col1, col2 ]
    # contents: 2D array of data [ [row1col1, row1col2], [row2col1, row2col2] ]
    def write_csv(file_name, headers, contents)
      return if Rails.env.test?
      file_path = File.join(Rails.application.root, "tmp", file_name)
      CSV.open(file_path, "wb") do |csv|
        csv << headers
        contents.each do |row|
          csv << row
        end
      end
    end

  end
end