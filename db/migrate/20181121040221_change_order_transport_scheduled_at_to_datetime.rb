class ChangeOrderTransportScheduledAtToDatetime < ActiveRecord::Migration

  def has_valid_timeslot(transport)
    ts = transport.timeslot
    transport.scheduled_at.present? && ts.present? && (/^\d{1,2}(:\d{2})?(AM|PM)/ =~ ts) == 0
  end

  def up
    change_column :order_transports, :scheduled_at, :datetime

    OrderTransport.find_each do |transport|
      unless has_valid_timeslot(transport)
        Rails.logger.warn "OrderTransport #{transport.id} has missing or invalid timeslot"
        next
      end

      time = Time.parse transport.timeslot.split('-').first
      timestamp = transport
        .scheduled_at
        .to_datetime
        .in_time_zone
        .change(hour: time.hour, min: time.min)
        .utc

      ActiveRecord::Base.connection.execute <<-SQL 
        UPDATE order_transports
        SET scheduled_at = \'#{timestamp.to_s(:db)}\'
        WHERE id = #{transport.id}
      SQL
    end
  end
 
   def down
    change_column :order_transports, :scheduled_at, :date
   end
end
