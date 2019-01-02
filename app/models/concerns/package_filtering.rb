# Filtering and priority logic for items is extracted here to avoid cluttering the model class
module PackageFiltering
  extend ActiveSupport::Concern

  module ClassMethods
    # Filter based on states, location, publish status and images

    def filter(states: [], location: nil, published: nil, images: nil)
      res = where(nil)
      res = res.where_states(states) unless states.empty?
      res = res.filter_by_location(location) unless location.blank?
      res
    end

    def where_states(states)
      states = states.select { |t| respond_to?("#{t}_sql") }
      return none if states.empty?

      queries = states.map do |t|
        method = "#{t}_sql"
        "(#{send(method)})"
      end
      states_sql = queries.compact.join(" OR ")
      join_order_packages.where(states_sql)
    end

    def join_order_packages
      joins("LEFT OUTER JOIN orders_packages ON orders_packages.package_id = packages.id")
    end

    def in_stock_sql
      "packages.state = 'received' and packages.quantity > 0"
    end

    def designated_sql
      "orders_packages.state = 'designated'"
    end

    def dispatched_sql
      "orders_packages.state = 'dispatched'"
    end

    def filter_by_location(location)
      building_name, area_name = location.split('-')
      if area_name === "(All areas)"
        where("locations.building = (?)", building_name)
      else
        where("locations.building = (?) AND locations.area = (?)", building_name, area_name)
      end
    end
  end
end
