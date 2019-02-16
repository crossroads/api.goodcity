#
# The logic for who to send a message to is already encapsulated in the
#   MessageSubscription module. This means the push update and in-app/mobile
#   notification can be hooked in via the Subscription class.
#   There is one subscription, per user, per message so send this push update
#   direct to subscription.user_id 

module PushUpdatesForSubscription
  extend ActiveSupport::Concern

  def update_client_store
    data = { 
      item: serialized_message,
      sender: serialized_user,
      operation: :create
    }
    channel = Channel.private_channel_for(self.user_id, app_name)
    PushService.new.send_update_store(channel, app_name, data)
  end

  private

  def serialized_message
    associations = Message.reflections.keys.map(&:to_sym)
    Api::V1::MessageSerializer.new(self.message, { exclude: associations })
  end

  # Determine which app to send it push update to.
  # If recipient of message is also owner of its related_object, then send to donor/browse
  # otherwise they are performing admin actions so send to Admin/Stock.
  # This should work for admins logged in to DONOR app who create messages on their own offers.
  def app_name
    klass_name = self.related_object.class.name
    created_by_id = self.related_object.created_by_id
    if klass_name == 'Order'
      (self.user_id == created_by_id) ? BROWSE_APP : STOCK_APP
    else # Offer / Item
      (self.user_id == created_by_id) ? DONOR_APP : ADMIN_APP
    end
  end
  
  def serialized_user
    Api::V1::UserSerializer.new(self.user)
  end

end
