# Search and filter logic for items is extracted here to avoid cluttering the model class
module PackageFiltering
  extend ActiveSupport::Concern
  included do
    # Free text search on packages
    scope :search, -> (options = {}) {
      search_text = options[:search_text] || ''
      item_id = options[:item_id] || ''
      state = options[:state] || ''
      if item_id.present?
        where("item_id = ?", item_id)
      else
        search_query = ['inventory_number', 'designation_name', 'notes', 'case_number'].
          map { |f| "packages.#{f} ILIKE :search_text" }.
          join(" OR ")
        query = where(search_query, search_text: "%#{search_text}%")
        query = query.inventorized if options[:with_inventory_no].present?
        query = query.not_multi_quantity if options[:restrict_multi_quantity].present?
        query = query.where(state: state) if state.present?
        query.order(updated_at: :desc)
      end
    }

  end

  module ClassMethods

    # Filter based on states, location, publish status and images
    # options
    #   state
    #     in_stock, received, designated, dispatched
    #     either 'published' or 'private',
    #     either 'has_images' or 'no_images'
    #   location
    #     (building_name)-(area_name)
    #     28-(All areas)
    #     28-Room1
    def filter(options={})
      states = (options['state'] || '').strip.split(',') || []
      location = options['location']

      query = where(nil)
      state_filters = states & %w[in_stock received designated dispatched]
      query = query.where_states(state_filters) if state_filters.any?
      query = query.filter_by_location(location) if location.present?

      publish_filters = states & %w[published private]
      query = query.filter_by_publish_status(publish_filters) if publish_filters.any?

      image_filters = states & %w[has_images no_images]
      query = query.filter_by_image_status(image_filters) if image_filters.any?
      query.distinct
    end

    def where_states(states)
      sql_query = states.map{|state| send("#{state}_sql") }.join(' OR ')
      return none if sql_query.blank?
      query = where(sql_query)
      query = query.join_order_packages if (states & ['designated', 'dispatched']).any?
      query
    end

    def filter_by_publish_status(publish_filters)
      if publish_filters.include?('published')
        where(allow_web_publish: true)
      elsif publish_filters.include?('private')
        where("(allow_web_publish IS NULL) or allow_web_publish = false")
      else
        where(nil)
      end
    end

    def filter_by_image_status(image_filters)
      if image_filters.include?('has_images')
        joins(:images).where("images.imageable_id = packages.id and images.imageable_type='Package'")
      elsif image_filters.include?('no_images')
        includes(:images).where(images: { imageable_id: nil })
      end
    end

    def filter_by_location(location_name)
      # to use postgresql indexes search location first and join packages_locations after
      building_name, area_name = location_name.split('-', 2)
      location =
        if area_name == '(All areas)'
          Location.where(building: building_name)
        else
          Location.where(building: building_name, area: area_name)
        end
      location_id = location.first.id.presence
      if location_id
        where('packages_locations.location_id = ?', location_id).
          joins("LEFT OUTER JOIN packages_locations ON packages_locations.package_id = packages.id")
      else
        where(nil) # noop
      end
    end

    def join_order_packages
      joins("LEFT OUTER JOIN orders_packages ON orders_packages.package_id = packages.id")
    end

    private

    def received_sql
      "packages.state = 'received'"
    end

    def in_stock_sql
      "packages.state = 'received' AND packages.quantity > 0"
    end

    def designated_sql
      "orders_packages.state = 'designated'"
    end

    def dispatched_sql
      "orders_packages.state = 'dispatched'"
    end

  end
end
