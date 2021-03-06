module PushUpdatesForSubscription
  extend ActiveSupport::Concern

  # Send in-app/mobile notifications to users who are subscribed to messages
  #   (see MessageSubscription module for logic).
  # E.g. after_create :send_new_message_notification
  def send_new_message_notification
    message = self.message
    # Don't notify the message sender themselves
    return if message.sender_id == user_id
    channel = Channel.private_channels_for(user_id, app_name)
    PushService.new.send_notification(channel, app_name, data_to_send)
  end

  private

  # Determine which app to send the in-app/mobile push notification to.
  # If recipient of message is also the owner of the related_object (offer/order),
  # then send to Donor/Browse otherwise user is an admin so send to Admin/Stock.
  # This should work for admins logged in to donor app who send messages on their own offers.
  def app_name
    related_object = message.related_object
    klass_name = related_object.class.name
    created_by_id = related_object.try(:created_by_id)

    if klass_name == "Order"
      (self.user_id == created_by_id) ? BROWSE_APP : STOCK_APP
    elsif ["Offer", "Item"].include?(klass_name)
      (self.user_id == created_by_id) ? DONOR_APP : ADMIN_APP
    elsif ["OfferResponse"].include?(klass_name)
      (self.user_id == created_by_id) ? BROWSE_APP : ADMIN_APP
    elsif klass_name == "Package"
      STOCK_APP
    end
  end

  def data_to_send
    # Deprication: item_id and data[identity] will be removed
    data = { category: 'message',
             message: message_body,
             is_private: message.is_private,
             item_id: item_id,
             author_id: message.sender_id,
             message_id: message.id,
             offer_id: offer_id,
             messageable_id: message.messageable_id,
             messageable_type: message.messageable_type }
    data[identity] = message.related_object.id
    data
  end

  def message_body
    message.parsed_body.truncate(150, separator: ' ')
  end

  #Sending offer_id as params for in-app notification of offer responses
  def offer_id
    message.messageable.instance_of?(OfferResponse) && message.messageable.offer_id
  end

  # Deprication: This will be removed
  def item_id
    message.messageable.instance_of?(Item) && message.messageable_id
  end

  # Deprication: This will be removed
  def identity
    "#{message.related_object.class.name.underscore}_id".to_sym
  end
end
