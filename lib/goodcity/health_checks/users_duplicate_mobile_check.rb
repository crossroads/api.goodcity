require 'goodcity/health_checks/base'

module Goodcity
  class HealthChecks
    class UsersDuplicateMobileCheck < Base
      desc "Users should not contain duplicate mobile addresses."
      def run
        sql = 
          <<-SQL
          WITH users_with_mobile_count AS (
            SELECT users.*, COUNT(id) OVER (PARTITION BY mobile) AS count
            FROM users
            WHERE mobile IS NOT NULL AND mobile <> ''
          )
          SELECT mobile from users_with_mobile_count WHERE count > 1 ORDER BY mobile, id;
          SQL
        result = User.connection.execute(sql).map{|res| res['mobile']}.uniq.compact
        if result.empty?
          pass!
        else
          fail_with_message!("GoodCity Users with duplicate mobiles (#{result.size}): #{result.join('; ')}")
        end
      end
    end
  end
end
