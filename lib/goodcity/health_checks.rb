require 'goodcity/health_checks/location_stockit_id_nil_check'
require 'goodcity/health_checks/dispatched_packages_order_id_check'
require 'goodcity/health_checks/received_packages_location_id_check'
require 'goodcity/health_checks/package_stockit_id_nil_check'
require 'goodcity/health_checks/order_stockit_id_nil_check'
require 'goodcity/health_checks/orders_packages_order_id_check'

module Goodcity
  class HealthChecks

    def initialize
      @checks = []
      register_check(LocationStockitIdNilCheck)
      register_check(DispatchedPackagesOrderIdCheck)
      register_check(ReceivedPackagesLocationIdCheck)
      register_check(PackageStockitIdNilCheck)
      register_check(OrderStockitIdNilCheck)
      register_check(OrdersPackagesOrderIdCheck)
    end

    def run
      @checks.map do |check|
        check.run
        report(check)
      end
    end

    def list_checks
      @checks.map{ |check| "#{check.name} - #{check.desc}" }.join("\n")
    end

    def report(check)
      output = "#{check.status} #{check.name}"
      output << " - #{check.message}" unless check.message.blank?
      output
    end

    private

    def register_check(klass)
      @checks << klass.new
    end

  end
end
