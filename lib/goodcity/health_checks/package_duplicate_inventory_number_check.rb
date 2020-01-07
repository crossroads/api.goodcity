require 'goodcity/health_checks/base'

module Goodcity
  class HealthChecks
    class PackageDuplicateInventoryNumberCheck < Base
      desc "Packages should not have duplicate inventory_numbers."
      def run
        ids = Package.select(:inventory_number).
          group(:inventory_number).
          having('COUNT(*) > 1').
          where('inventory_number IS NOT NULL').
          pluck(:inventory_number)
        if ids.empty?
          pass!
        else
          fail_with_message!("GoodCity Packages with duplicate inventory_numbers. inventory_numbers (#{ids.size}): #{ids.join(', ')}")
        end
      end
    end
  end
end
