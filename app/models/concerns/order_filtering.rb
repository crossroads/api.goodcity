# Filtering and priority logic for orders is extracted here to avoid cluttering the model class
module OrderFiltering
  extend ActiveSupport::Concern

  def is_priority?
    self.class.priority.exists?(self.id)
  end

  module ClassMethods
    def priority
      join_order_transports.where <<-SQL
        (state = 'submitted' AND submitted_at::timestamptz <= timestamptz '#{one_day_ago}') OR
        (state = 'processing' AND processed_at::timestamptz < timestamptz '#{last_6pm}') OR
        (state = 'awaiting_dispatch' AND order_transports.scheduled_at::timestamptz < timestamptz '#{Time.now}') OR
        (state = 'dispatching' AND dispatch_started_at::timestamptz < timestamptz '#{last_6pm}')
      SQL
    end

    #
    # Returns orders filtered using the following options :
    #   - states[] A list of string matching the 'state' column of the order
    #   - types[] A list of custom types, each defined by a combination or properties
    #   - priority? Whether to only return orders deemed as 'high priority' or not
    #
    # Available types to filter on
    #   - appointment
    #   - online_order_pickup
    #   - online_order_ggv
    #   - shipment
    #   - other
    #
    # To add a custom type, add an sql returning method formatted as {type_name}_sql
    # e.g :
    #   def shipment_sql
    #     "detail_type = 'shipment'"
    #   end
    #
    def filter(states: [], types: [], priority: false)
      res = all
      res = res.where("state IN (?)", states) unless states.empty?
      res = res.where_types(types) unless types.empty?
      res = res.priority if priority.present?
      res
    end

    def where_types(types)
      types = types.select { |t| respond_to?("#{t}_sql") }
      return none if types.empty?

      queries = types.map do |t|
        method = "#{t}_sql"
        "(#{send(method)})"
      end
      join_order_transports.where(queries.compact.join(" OR "))
    end

    def join_order_transports
      joins("LEFT OUTER JOIN order_transports ON order_transports.order_id = orders.id")
    end

    # TYPES

    def appointment_sql
      "order_transports.booking_type_id = #{BookingType.appointment.id}"
    end

    def online_order_pickup_sql
      "order_transports.booking_type_id = #{BookingType.online_order.id} AND order_transports.transport_type = 'self'"
    end

    def online_order_ggv_sql
      "order_transports.booking_type_id = #{BookingType.online_order.id} AND order_transports.transport_type = 'ggv'"
    end

    def shipment_sql
      "lower(detail_type) LIKE 'shipment'"
    end

    def other_sql
      "lower(detail_type) NOT IN ('goodcity', 'shipment', 'stockitlocalorder')"
    end

    # HELPERS

    def last_6pm
      now = Time.now.in_time_zone
      t = now.change(hour: 18, min: 0, sec: 0)
      t -= 24.hours if now < t
      t
    end

    def one_day_ago
      Time.now - 24.hours
    end
  end
end
