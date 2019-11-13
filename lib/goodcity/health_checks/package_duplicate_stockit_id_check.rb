require 'goodcity/health_checks/base'

module Goodcity
  class HealthChecks
    class PackageDuplicateStockitIdCheck < Base
      desc "Packages should not have duplicate stockit_ids."
      def run
        ids = Package.where(stockit_id: nil).pluck(:id)
        ids = Package.select(:stockit_id).group(:stockit_id).having('COUNT(*) > 1').where('stockit_id IS NOT NULL').pluck(:stockit_id)
        if ids.count.zero?
          pass!
        else
          fail_with_message!("GoodCity Packages with duplicate stockit_ids. stockit_id: #{ids.join(', ')}")
        end
      end
    end
  end
end
