module Goodcity
  module PackageSetup

    module_function

    def compute_quantities
      iterate { |package| PackagesInventory::Computer.update_package_quantities(package) }
    end

    def iterate
      progress = RakeProgressbar.new(Package.count)
      Package.find_each do |package|
        yield(package)
        progress.inc
      end
      progress.finished
    end
  end
end