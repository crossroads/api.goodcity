require 'goodcity/health_checks/base'

module Goodcity
  class HealthChecks
    class PackageReceivedLocationIdCheck < Base
      desc "Packages should have received_quantity > 0."
      def run
        ids = Package.where('received_quantity < 1').pluck(:id)
        if ids.empty?
          pass!
        else
          fail_with_message!("GoodCity Packages with received_quantity < 1. packages.id (#{ids.size}): #{ids.join(', ')}")
        end
      end
    end
  end
end
