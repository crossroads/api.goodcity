require 'goodcity/health_checks/location_stockit_id_nil_check'
require 'goodcity/health_checks/dispatched_packages_order_id_check'
require 'goodcity/health_checks/received_packages_location_id_check'
require 'goodcity/health_checks/package_stockit_id_nil_check'
require 'goodcity/health_checks/order_stockit_id_nil_check'
require 'goodcity/health_checks/orders_packages_order_id_check'
require 'goodcity/health_checks/package_type_stockit_id_nil_check'
require 'goodcity/health_checks/item_packages_check'

module Goodcity
  class HealthChecks

    cattr_accessor :checks
    @@checks = []
    
    class << self

      # # Array of check classes (not instances)
      # def checks
      #   @@checks ||= []
      # end

      # Usage
      #   register_check(CheckClass)
      def register_check(check)
        checks << check
      end

      def run_all
        checks.map do |check_klass|
          check = check_klass.new
          check.run
          check.report
        end
      end

      def list_checks
        checks.map do |check|
          "#{check.name} - #{check.desc}"
        end.join("\n")
      end

      # run hook to register health_checks
      ActiveSupport.run_load_hooks(:health_checks, Goodcity::HealthChecks)

    end # class
    
  end
end
