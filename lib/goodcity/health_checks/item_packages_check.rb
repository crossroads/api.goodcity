require 'goodcity/health_checks/base'

module Goodcity
  class HealthChecks
    class ItemPackagesCheck < Goodcity::HealthChecks::Base

      desc "Accepted (not deleted) items should have at least 1 related package."
      def run
        ids = Item.where(state: 'accepted').
                   where('NOT EXISTS (SELECT 1 FROM packages WHERE packages.item_id = items.id)').
                   select(:id).
                   pluck(:id)
        if ids.size == 0
          pass!
        else
          fail_with_message!("GoodCity accepted (not deleted) items with no related packages. items.id (#{ids.size}): #{ids.join(', ')}")
        end
      end

    end
  end
end
