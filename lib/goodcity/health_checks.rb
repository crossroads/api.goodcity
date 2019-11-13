require 'goodcity/health_checks/item_packages_check'
require 'goodcity/health_checks/location_stockit_id_nil_check'
require 'goodcity/health_checks/order_stockit_id_nil_check'
require 'goodcity/health_checks/orders_package_duplicates_check'
require 'goodcity/health_checks/orders_package_designated_but_sent_check'
require 'goodcity/health_checks/orders_package_not_dispatched_but_stockit_sent_on_set_check'
require 'goodcity/health_checks/orders_package_order_id_check'
require 'goodcity/health_checks/orders_package_state_dispatched_sent_on_nil_check'
require 'goodcity/health_checks/orders_package_zero_quantity_check'
require 'goodcity/health_checks/package_stockit_id_nil_check'
require 'goodcity/health_checks/package_dispatched_order_id_nil_check'
require 'goodcity/health_checks/package_duplicate_inventory_number_check'
require 'goodcity/health_checks/package_duplicate_stockit_id_check'
require 'goodcity/health_checks/package_received_location_id_check'
require 'goodcity/health_checks/package_type_stockit_id_nil_check'
# require 'goodcity/health_checks/missing_ids_and_inventory_numbers_check' # Best run standalone from rails console

module Goodcity
  class HealthChecks

    cattr_accessor :checks
    @@checks = []
    
    class << self

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
