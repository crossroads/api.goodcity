module PushUpdatesForSubscription
  extend ActiveSupport::Concern

  # Send in-app/mobile notifications to users who are subscribed to messages
  #   (see MessageSubscription module for logic).
  # E.g. after_create :send_new_message_notification
  def send_new_message_notification
    message = self.message
    # Don't notify the message sender themselves
    return if message.sender_id == self.user_id
    data = {
      category:   'message',
      message:    message.body.truncate(150, separator: ' '),
      is_private: message.is_private,
      offer_id:   message.offer_id,
      order_id:   message.order_id,
      item_id:    message.item_id,
      author_id:  message.sender_id,
      message_id: message.id
    }
    channel = Channel.private_channels_for(self.user_id, app_name)
    PushService.new.send_notification(channel, app_name, data)
  end

  private

  # Determine which app to send the in-app/mobile push notification to.
  # If recipient of message is also the owner of the related_object (offer/order),
  # then send to Donor/Browse otherwise user is an admin so send to Admin/Stock.
  # This should work for admins logged in to donor app who send messages on their own offers.
  def app_name
    related_object = self.message.related_object
    klass_name = related_object.class.name
    created_by_id = related_object.created_by_id
    if klass_name == 'Order'
      (self.user_id == created_by_id) ? BROWSE_APP : STOCK_APP
    else # Offer / Item
      (self.user_id == created_by_id) ? DONOR_APP : ADMIN_APP
    end
  end

end
