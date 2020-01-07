# received_quantity should equal any orders_package.quantity and packages_locations.quantity
# until Stockit is removed
require 'goodcity/health_checks/base'

module Goodcity
  class HealthChecks
    class QuantityCheck < Base
      desc "received_quantity should equal any orders_packages.quantity and packages_locations.quantity"
      def run
        sql = 
          <<-SQL
          SELECT packages.id AS id
          FROM packages
          LEFT JOIN orders_packages ON orders_packages.package_id=packages.id
          WHERE orders_packages.state IN ('designated', 'dispatched')
            AND packages.received_quantity != orders_packages.quantity
          SQL
        result = Package.connection.execute(sql).map{|res| res['id']}.uniq.compact
        sql = 
          <<-SQL
          SELECT packages.id AS id
          FROM packages
          LEFT JOIN packages_locations ON packages_locations.package_id=packages.id
          WHERE packages.received_quantity != packages_locations.quantity
          SQL
        result2 = Package.connection.execute(sql).map{|res| res['id']}.uniq.compact
        result = (result + result2).uniq.compact
        if result.empty?
          pass!
        else
          fail_with_message!("GoodCity Packages.received_quantity unmatched with either orders_packages.quantity or packages_locations.quantity (#{result.size}): #{result.join('; ')}")
        end
      end
    end
  end
end
