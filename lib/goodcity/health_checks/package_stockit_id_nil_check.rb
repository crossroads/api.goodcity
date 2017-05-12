require 'goodcity/health_checks/base'

module Goodcity
  class HealthChecks

    class PackageStockitIdNilCheck < Base
      desc "Packages should contain a stockit_id reference."
      def run
        ids = Package.where(stockit_id: nil).pluck(:id)
        if ids.count == 0
          pass!
        else
          fail_with_message!("GoodCity Packages with nil stockit_id: #{ids.join(', ')}")
        end
      end
    end

  end
end
