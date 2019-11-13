require 'goodcity/health_checks/base'

module Goodcity
  class HealthChecks
    class PackageStockitIdNilCheck < Base
      desc "Packages should contain a stockit_id reference."
      def run
        ids = Package.where(stockit_id: nil).pluck(:id)
        if ids.count.zero?
          pass!
        else
          fail_with_message!("GoodCity Packages with nil stockit_id. packages.id (#{ids.size}): #{ids.join(', ')}")
        end
      end
    end
  end
end
