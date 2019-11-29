require 'goodcity/health_checks/base'

module Goodcity
  class HealthChecks
    class OrdersPackageDuplicateCheck < Base
      desc "There should be < 2 designated or dispatched record per package"
      def run
        sql = 
          <<-SQL
          WITH dispatched_orders_packages_count AS (
            SELECT orders_packages.*, COUNT(id) OVER (PARTITION BY package_id) AS count
            FROM orders_packages
            WHERE orders_packages.state IN ('designated', 'dispatched')
          )
          SELECT id from dispatched_orders_packages_count WHERE count > 1 ORDER BY package_id, order_id, state, id;
          SQL
        result = User.connection.execute(sql).map{|res| res['id']}.compact
        if result.empty?
          pass!
        else
          fail_with_message!("GoodCity Packages with more than one designated or dispatched order (#{result.size}): #{result.join('; ')}")
        end
      end
    end
  end
end
