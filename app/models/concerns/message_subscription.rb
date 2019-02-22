#
# Logic for which users to subscribe to each new message
module MessageSubscription
  extend ActiveSupport::Concern

  # Who gets subscribed to a new message (i.e. who can see each message)
  def subscribe_users_to_message
    obj = self.related_object
    klass = obj.class.name.underscore
    user_ids = []

    # Add the following users
    #   - Donor / Charity user
    #   - Message sender
    #   - Anyone who has previously replied to offer/order
    #   - Admin users processing the offer/order
    user_ids << obj.try(:created_by_id)
    user_ids << self.sender_id
    user_ids += Subscription.where("#{klass}_id": obj.id).pluck(:user_id)
    admin_user_fields.each{|field| user_ids << obj.try(field)}

    # Remove the following users
    #   - SystemUser and StockitUser
    #   - donor/charity user if the message is private (supervisor channel) or offer/order is cancelled
    user_ids = user_ids.flatten.uniq
    user_ids -= [User.system_user.try(:id), User.stockit_user.try(:id)]
    user_ids -= [obj.try(:created_by_id)] if self.is_private or obj.try('cancelled?')

    # For private messages, subscribe all supervisors when there are no others subscribed.
    user_ids += User.supervisors.pluck(:id) if self.is_private and user_ids.size < 2

    user_ids.flatten.compact.uniq.each do |user_id|
      state = (user_id == self.sender_id) ? "read" : "unread" # mark as read for sender
      add_subscription(state, user_id)
    end
  end

  private

  def admin_user_fields
    [:reviewed_by_id, :processed_by_id, :process_completed_by_id,  :cancelled_by_id, :process_completed_by,
      :dispatch_started_by, :closed_by, :submitted_by]
  end

  def add_subscription(state, user_id)
    subscriptions.create(
      state: state,
      message_id: self.id,
      offer_id: self.offer_id,
      order_id: self.order_id,
      user_id: user_id)
  end

end
