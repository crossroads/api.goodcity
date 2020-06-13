class PackageDeduplicator

  def initialize(inventory_numbers, options = {})
    @dry_run = (options[:dry_run] == true)
    @inventory_numbers = [inventory_numbers].flatten.uniq
    @log_entries = []
    @headers = ['inventory_number', 'msg', 'id', 'order state', 'created_at', 'order name', 'location', 'dry run']
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
    write_log_file
  end

  private

  # Given an array of packages, choose one to keep and merge the others into it
  # Fields:
  #   - item_id (i.e. part of an offer)
  #   - orders_packages (i.e. has a designation)
  #   - 
  # Rules
  #   - prefer NON NULL data over NULL data
  #   - prefer newer data over older data
  def merge_packages(packages)
    values = packages.dup.sort_by{ |v| v.updated_at}.reverse # newest first
    values = values.
    [ values.shift, values] # package_to_keep, packages_to_destroy
  end

  def destroy_packages(packages_to_destroy)
    packages_to_destroy.each do |package|
      if package.item_id or package.orders_packages
        log(package.inventory_number, "#{package.id} not destroying as it has item_id or orders_packages record")
        next
      else
        log(inventory_number, "Deleting package,", package.id)
        PackageDestroyer.destroy(package, dry_run: @dry_run)
      end
    end
  end

  def log(inventory_number, msg, package = nil)
    package_details = []
    if package
      package_details = %w(id created_at).map{|attr| package.send(attr)}
      order = package.orders_packages.map(&:order).first
      package_details += [order.code, order.state, order.closed_at]
      location_ids = PackagesInventory.where(package_id: package.id).pluck(:location_id)
      package_details << Location.where(id: location_ids).map(&:label).join(", ")
      package_details << "#{@dry_run}"
    end
    puts "#{inventory_number} : #{msg} : #{package_details.join(', ')}"
    @log_entries << ([inventory_number, msg] + package_details)
  end

end
