# Filtering logic for items is extracted here to avoid cluttering the model class
module PackageFiltering
  extend ActiveSupport::Concern

  module ClassMethods
    # Filter based on states, location, publish status and images

    def filter(states: [], location: nil)
      res = where(nil)
      package_state = states & %w[in_stock received designated dispatched]
      res = res.where_states(package_state) if package_state.any?
      res = res.filter_by_location(location) unless location.blank?

      publish_filters = states & %w[published private]
      res = res.filter_by_publish_status(publish_filters) if publish_filters.presence

      image_filters = states & %w[has_images no_images]
      res = res.filter_by_image_status(image_filters) if image_filters.presence
      res.uniq
    end

    def where_states(states)
      states = states.select { |t| respond_to?("#{t}_sql") }
      return none if states.empty?

      queries = states.map do |t|
        method = "#{t}_sql"
        send(method)
      end
      states_sql = queries.compact.join(" OR ")
      join_order_packages.where(states_sql)
    end

    def join_order_packages
      joins("LEFT OUTER JOIN orders_packages ON orders_packages.package_id = packages.id")
    end

    def received_sql
      "packages.state = 'received'"
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

    def filter_by_publish_status(publish_filters)
      if publish_filters.include?('published')
        where(allow_web_publish: true)
      elsif publish_filters.include?('private')
        where("(allow_web_publish IS NULL) or allow_web_publish = false")
      end
    end

    def filter_by_image_status(image_filters)
      if image_filters.include?('has_images')
        joins(:images).where("images.imageable_id = packages.id and images.imageable_type='Package'")
      elsif image_filters.include?('no_images')
        includes(:images).where(images: { imageable_id: nil })
      end
    end

    def filter_by_location(location)
      building_name, area_name = location.split('-', 2)
      if area_name == '(All areas)'
        where("locations.building = (?)", building_name)
      else
        where("locations.building = (?) AND locations.area = (?)", building_name, area_name)
      end
    end
  end
end
