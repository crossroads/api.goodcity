require 'goodcity/health_checks/base'

module Goodcity
  class HealthChecks
    class UsersDuplicateEmailCheck < Base
      desc "Users should not contain duplicate email addresses."
      def run
        sql = 
          <<-SQL
          WITH users_with_email_count AS (
            SELECT users.*, COUNT(id) OVER (PARTITION BY email) AS count
            FROM users
            WHERE email IS NOT NULL AND email <> ''
          )
          SELECT email from users_with_email_count WHERE count > 1 ORDER BY email, id;
          SQL
        result = User.connection.execute(sql).map{|res| res['email']}.uniq.compact
        if result.empty?
          pass!
        else
          fail_with_message!("GoodCity Users with duplicate emails (#{result.size}): #{result.join('; ')}")
        end
      end
    end
  end
end
