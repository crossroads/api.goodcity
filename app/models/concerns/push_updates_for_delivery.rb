#
# Logic for who gets notified about changes to deliveries
#
module PushUpdatesForDelivery
  extend ActiveSupport::Concern
  
  # When a delivery is created/updated, send:
  #  - data updates to the offer donor
  #  - data updates admin staff (since this will be an active offer)
  def send_updates(operation = nil)
    records.each do |record|
      operation ||= (record.class == 'Delivery' ? "update" : "create")
      data = { item: serialized_object(record), sender: serialized_sender, operation: operation }
      push_updates(data)
    end
    return true
  end

  # In-app and mobile notification to reviewers
  #   that a delivery has been scheduled (new or existing)
  def notify_reviewers
    PushService.new.send_notification(Channel::REVIEWER_CHANNEL, ADMIN_APP, {
      category: 'offer_delivery',
      message:   delivery_notify_message,
      offer_id:  offer.id,
      author_id: offer.created_by_id
    })
  end

  private

  # In it's own method to make it easier to test
  def records
    [gogovan_order, contact.try(:address), contact, schedule, self].compact
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

  def delivery_notify_message
    formatted_date = schedule.scheduled_at.strftime("%a #{schedule.scheduled_at.day.ordinalize} %b %Y")
    I18n.t("delivery.#{delivery_type.downcase.tr(' ', '_')}_message",
      name: donor.full_name,
      time: schedule.slot_name,
      date: formatted_date)
  end
  
end