#
# Logic for which users to subscribe to each new message
module MessageSubscriptions
  extend ActiveSupport::Concern

  # Who gets subscribed to a new message (i.e. who can see each message)
  def subscribe_users_to_message
    obj = related_object
    user_ids = []
    # Add the following users
    #   - Donor / Charity user
    #   - Message sender
    #   - Anyone who has previously replied to offer/order
    #   - Admin users processing the offer/order
    user_ids << obj.try(:created_by_id)
    user_ids << sender_id
    user_ids += public_subscribers_to(obj)
    user_ids += private_subscribers_to(obj)
    admin_user_fields.each { |field| user_ids << obj.try(field) }

    # Remove the following users
    #   - SystemUser and StockitUser
    #   - donor/charity user if the message is private (supervisor channel) or offer/order is cancelled
    user_ids = user_ids.flatten.uniq
    user_ids -= [User.system_user.try(:id), User.stockit_user.try(:id)]
    user_ids -= [obj.try(:created_by_id)] if is_private || obj.try('cancelled?')

    # Cases where we subscribe every staff member
    #  - For private messages, subscribe all supervisors ONLY for the first message
    #  - If donor sends a message but no one else is listening, subscribe all reviewers.
    subscribe_all_staff = if is_private
                            first_message?
                          else
                            obj&.created_by_id.present? && (user_ids.uniq.compact == [sender_id])
                          end

    user_ids += User.staff.pluck(:id) if subscribe_all_staff
    user_ids += mentioned_ids if mentioned_ids.present?

    user_ids.flatten.compact.uniq.each do |user_id|
      state = user_id == sender_id ? 'read' : 'unread' # mark as read for sender
      add_subscription(state, user_id)
    end
  end

  private

  # A public subscriber is defined as :
  #   > Anyone who has a subscription to that record
  def public_subscribers_to(obj)
    Subscription
      .joins(:message)
      .where(subscribable: obj, messages: { is_private: false })
      .pluck(:user_id)
  end

  # A private subscriber is defined as :
  #   > A supervisor or reviewer who has answered the private thread
  def private_subscribers_to(obj)
    User.staff
        .joins(messages: [:subscriptions])
        .where(messages: { is_private: true })
        .where(subscriptions: { subscribable: obj })
        .pluck(:id)
  end

  def first_message?
    Message.where(is_private: is_private, messageable: messageable).count.eql? 1
  end

  def admin_user_fields
    %i[reviewed_by_id processed_by_id process_completed_by_id cancelled_by_id
       process_completed_by dispatch_started_by closed_by submitted_by]
  end

  def add_subscription(state, user_id)
    subscriptions.create(
      state: state,
      subscribable: messageable,
      user_id: user_id
    )
  end
end
