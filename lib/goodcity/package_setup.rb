require 'classes/csv_writer'

module Goodcity
  module PackageSetup

    module_function

    def compute_quantities(rehearse: false)
      errors = CsvWriter.new
      count = 0
      iterate do |package|
        quantities = PackagesInventory::Computer.package_quantity_summary(package)
        package.assign_attributes(quantities)
        if package.valid? && !rehearse
          package.update_columns(quantities)
          count += 1
        elsif !package.valid?
          errors.add_object({ package: package.id, error: package.errors.first.to_s }.merge(quantities))
        end
      end

      puts "== Results =="
      puts "* UPDATES: #{count}/#{Package.count} packages updated" unless rehearse
      unless errors.empty?
        puts "* FAILURES: #{errors.row_count} errors detected !"
        errors.to_file("packages_quantities_setup_errors")
      end
    end

    def iterate
      progress = RakeProgressbar.new(Package.count)
      Package.find_each do |package|
        ActiveRecord::Base.logger.silence { yield(package) }
        progress.inc
      end
      progress.finished
    end
  end
end