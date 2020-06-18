require "goodcity/package_destroyer"

module Goodcity
  class PackageDeduplicator

    def initialize(inventory_numbers, options = {})
      @dry_run = (options[:dry_run] == true)
      @inventory_numbers = [inventory_numbers].flatten.uniq
      @log_entries = []
    end

    def self.dedup(inventory_numbers, options = {})
      new(inventory_numbers, options).dedup
    end

    def dedup
      @inventory_numbers.each do |inventory_number|
        packages = Package.where(inventory_number: inventory_number)
        if packages.size > 1
          package_to_keep, packages_to_destroy = merge_packages(packages)
          log(inventory_number, "Keeping package ", package_to_keep)
          destroy_packages(packages_to_destroy)
        else
          log(inventory_number, "#{packages.size} records found, no duplicates.")
        end
      end
      write_log_file unless Rails.env.test? 
    end

    private

    # Given an array of packages, choose one to keep and merge the others into it
    # Fields:
    #   - item_id (i.e. part of an offer) - keep the oldest one
    #   - orders_packages (i.e. has a designation)
    # 
    # Rules
    #   - prefer NON NULL data over NULL data
    #   - prefer newer data over older data
    def merge_packages(packages)
      packages_with_item_id = packages.dup.select{ |pkg| pkg.item_id.present? }.sort_by{ |v| v.updated_at }
      values = packages.dup.sort_by{ |v| v.created_at } # oldest first
      values = (packages_with_item_id + values).uniq
      [ values.shift, values ] # package_to_keep, packages_to_destroy
    end

    def destroy_packages(packages_to_destroy)
      ActiveRecord::Base.transaction do
        packages_to_destroy.each do |package|
          log(package.inventory_number, "Deleting package,", package)
          PackageDestroyer.destroy(package) unless @dry_run
        end
      end
    end

    def log(inventory_number, msg, package = nil)
      package_details = ""

      if package
        order = package.orders_packages.map(&:order).first
        order_details = order.blank? ? {} : order.attributes.slice("id", "code", "state", "closed_at")

        locations = Location.where(
          id: PackagesLocation.where(package_id: package.id).pluck(:location_id)
        ).map(&:label)

        package_details = {
          id: package.id,
          created_at: package.created_at,
          order: order_details,
          locations: locations
        }.to_json
      end

      puts "[#{inventory_number}] {msg} #{package_details}" unless Rails.env.test? 
      @log_entries << [inventory_number, msg, package_details]
    end

    def write_log_file
      filename = "package_deduplicator_output_#{Time.now.to_i}.txt"

      File.open(filename, "w+") do |f|
        @log_entries.each { |element| f.puts(element.join(',')) }
      end

      puts("#{filename} created");
    end

  end
end