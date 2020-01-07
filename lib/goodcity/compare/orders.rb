require 'goodcity/compare/base'

#
# Usage:
# > Goodcity::Compare::Orders.run
#
# Generates two huge SQL datasets for Stockit Designations and GoodCity orders
#   and determines how they differ
module Goodcity
  class Compare

    class Orders < Base

      # TODO
      #   detail_id, detail_type
      #   date fields
      #   created_at, updated_at,
      #   sent_on
      #   number_of_people_helped AS people_helped
      #   country_id
      def stockit_sql
        <<-SQL
        SELECT id AS stockit_id, code, description,
          contact_id AS stockit_contact_id, organisation_id AS stockit_organisation_id, activity_id AS stockit_activity_id,
          status
        FROM designations
        SQL
      end

      # countries.stockit_id AS country_id
      def goodcity_sql
        <<-SQL
        SELECT orders.stockit_id, code, description,
          stockit_contacts.stockit_id AS stockit_contact_id, stockit_organisations.stockit_id AS stockit_organisation_id,
          stockit_activity_id, status
        FROM orders
        LEFT JOIN countries ON countries.id=orders.country_id
        LEFT JOIN stockit_contacts ON stockit_contacts.id=orders.stockit_contact_id
        LEFT JOIN stockit_organisations ON stockit_organisations.id=orders.stockit_organisation_id
        SQL
      end

    end

  end
end