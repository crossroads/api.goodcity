#
# Logic for which users to subscribe to each new message
module MessageSubscriptions
  extend ActiveSupport::Concern

  # Who gets subscribed to a new message (i.e. who can see each message)
  def subscribe_users_to_message
    obj = messageable
    non_human_users = Message.non_human_senders

    # -> include all permitted staff members on the first message, or if nobody anwered the donor
    staff_ids = permitted_staff_members(messageable_type).pluck(:id) if first_message? || (!is_private && nobody_answered?)

    # -> for subsequent messages, only include active staff members
    staff_ids ||= active_staff_members(messageable_type, obj, is_private)

    # -> include staff members related to the object (reviewer, closer, etc...)
    admin_user_fields.each { |field| staff_ids << obj.try(field) }

    # -> include anyone that has been mentioned
    staff_ids += mentioned_ids if mentioned_ids.present?

    # -> include the sender
    user_ids = [sender_id] + staff_ids

    # -> if the message has a specified recipient, we include it
    user_ids << recipient_id if !is_private && recipient_id.present? && !obj.try(:cancelled?)

    user_ids.flatten.compact.uniq.each do |user_id|
      next if user_id.in?(non_human_users)

      state = user_id == sender_id ? 'read' : 'unread' # mark as read for sender
      add_subscription(state, user_id)
    end
  end

  def managed_by?(user)
    return false unless user.present? && messageable_type.present?

    perm = required_staff_permission(messageable_type)
    user.user_permissions_names.include?(perm)
  end

  private

  def required_staff_permission(klass)
    if ['Offer', 'Item'].include?(klass)
      return 'can_manage_offer_messages'
    end

    if ['OfferResponse'].include?(klass)
      return 'can_manage_offer_responses'
    end

    "can_manage_#{klass.underscore}_messages"
  end

  def permitted_staff_members(klass)
    return User.none unless klass.present?

    message_permission = required_staff_permission(klass)

    User.with_permissions(message_permission).distinct
  end

  def active_staff_members(klass, obj, is_private)
    permitted_staff_members(klass)
      .joins(:messages)
      .where('messages.sender_id = users.id')
      .where(messages: {is_private: is_private, messageable: obj })
      .pluck(:id)
      .uniq
  end

  def first_message?
    Message
      .unscoped
      .from_humans
      .where(is_private: is_private, messageable: messageable).count.eql? 1
  end

  def nobody_answered?
    senders = Message.from_humans.where(is_private: is_private, messageable: messageable).pluck(:sender_id).uniq
    senders.count.eql?(1) && senders.first.eql?(sender_id)
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
