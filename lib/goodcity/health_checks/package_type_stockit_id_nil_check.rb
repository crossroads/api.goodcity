require 'goodcity/health_checks/base'

module Goodcity
  class HealthChecks

    class PackageTypeStockitIdNilCheck < Base
      desc "PackageTypes should contain a stockit_id reference."
      def run
        ids = PackageType.where(stockit_id: nil).pluck(:id)
        if ids.count == 0
          pass!
        else
          fail_with_message!("GoodCity PackageTypes with nil stockit_id: #{ids.join(', ')}")
        end
      end
    end

  end
end
