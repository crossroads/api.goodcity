require 'goodcity/health_checks/base'

module Goodcity
  class HealthChecks

    class PackageStockitIdNilCheck < Base
      desc "Inventoried packages should contain a stockit_id reference."
      def run
        ids = Package.where(stockit_id: nil).where('inventory_number IS NOT NULL').pluck(:id)
        if ids.count == 0
          pass!
        else
          fail_with_message!("GoodCity inventoried packages with nil stockit_id: #{ids.join(', ')}")
        end
      end
    end

  end
end
