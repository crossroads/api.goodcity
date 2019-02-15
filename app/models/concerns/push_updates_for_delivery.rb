#
# Logic for who gets notified about changes to deliveries
#
# When a delivery is created/updated, send push updates to:
#   - the offer donor
#   - admin staff (since this will be an active offer)
#
module PushUpdatesForDelivery
  extend ActiveSupport::Concern
  
  def send_updates(operation = nil)
    records.compact.each do |record|
      operation ||= (record.class == 'Delivery' ? "update" : "create")
      data = { item: serialized_object(record), sender: serialized_sender, operation: operation }
      push_updates(data)
    end
    return true
  end

  private

  # In it's own method to make it easier to test
  def records
    [gogovan_order, contact.try(:address), contact, schedule, self]
  end

  # Send to donor on donor app
  # Send to staff on admin app
  def push_updates(data)
    PushService.new.send_update_store(Channel::STAFF_CHANNEL, ADMIN_APP, data)
    PushService.new.send_update_store(Channel.private_channels_for(donor, DONOR_APP), DONOR_APP, data)
  end

  # A delivery doesn't have a 'created_by' record so if an admin creates the delivery
  # we try to capture that here
  def serialized_sender
    user = User.current_user || donor
    Api::V1::UserSerializer.new(user)
  end

  def donor
    offer.created_by
  end

  def serialized_object(record)
    associations = record.class.reflections.keys.map(&:to_sym)
    "Api::V1::#{record.class}Serializer".constantize.new(record, { exclude: associations })
  end
  
end