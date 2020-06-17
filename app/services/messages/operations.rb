# frozen_string_literal: true

module Messages
  # Message operations
  class Operations < Base
    attr_accessor :message, :ids, :mentioned_ids

    def initialize(params)
      @message = params[:message]
      @ids = []
      super(params.merge(messageable: @message.messageable))
    end

    def self.handle_subscriptions(message)
      new(message).handle_subscriptions
    end

    def handle_subscriptions
      format_message_body
      subscribe_users_to_message
    end

    def subscribe_users_to_message
      obj = message.related_object
      # Add the following users
      #   - Donor / Charity user
      #   - Message sender
      #   - Anyone who has previously replied to offer/order
      #   - Admin users processing the offer/order
      add_related_users(obj)
      @ids = ids.flatten.uniq
      remove_unwanted_users(obj)
      add_mentioned_users
      add_all_subscribed_staff(obj)
      add_subscription_for_message
    end

    private

    def add_subscription_for_message
      ids.flatten.compact.uniq.each do |user_id|
        state = user_id == message.sender_id ? 'read' : 'unread' # mark as read for sender
        add_subscriber(user_id, state)
      end
    end

    # Cases where we subscribe every staff member
    #  - For private messages, subscribe all supervisors ONLY for the first message
    #  - If donor sends a message but no one else is listening, subscribe all reviewers.
    def subscribe_all_staff_for?(obj)
      if message.is_private
        first_message?
      else
        obj&.created_by_id.present? && (ids.compact.uniq == [message.sender_id])
      end
    end

    def first_message?
      Message.where(is_private: message.is_private, messageable: messageable).count.eql? 1
    end

    def remove_unwanted_users(obj)
      @ids -= [User.system_user.try(:id), User.stockit_user.try(:id)]
      @ids -= [obj.try(:created_by_id)] if message.is_private || obj.try('cancelled?')
    end

    def add_mentioned_users
      @ids += mentioned_ids if mentioned_ids.present?
    end

    def add_related_users(obj)
      add_sender_creator(obj)
      add_public_private_subscibers_for(obj)
      add_admin_user_fields_for(obj)
    end

    def add_all_subscribed_staff(obj)
      @ids += User.staff.pluck(:id) if subscribe_all_staff_for?(obj)
    end

    def add_sender_creator(obj)
      ids << obj&.created_by_id
      ids << message.sender_id
    end

    def add_admin_user_fields_for(obj)
      admin_user_fields.each { |field| ids << obj.try(field) }
    end

    def add_public_private_subscibers_for(obj)
      @ids += public_subscribers_to(obj)
      @ids += private_subscribers_to(obj)
    end

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

    def format_message_body
      sanitize_and_set_mentioned_ids
      return if mentioned_ids.empty?

      add_lookup
    end

    def admin_user_fields
      %i[reviewed_by_id processed_by_id process_completed_by_id cancelled_by_id
         process_completed_by dispatch_started_by closed_by submitted_by]
    end

    def sanitize_and_set_mentioned_ids
      ids = parse_id_from_mention_text
      ref_count = 0
      sanitize_user_ids(ids)
      message.body = message.body.gsub(/\[:\d+\]/) do
        ref_count += 1
        "[:#{ref_count}]"
      end
    end

    def sanitize_user_ids(ids)
      @mentioned_ids = parse_id_from_decorated_ids(ids)
    end

    def add_lookup
      lookup = {}
      lookup_ids = parse_id_from_decorated_ids(parse_id_from_mention_text)
      lookup_ids.map.with_index do |lookup_id, idx|
        lookup[lookup_id] = { type: 'User', id: mentioned_ids[idx], display_name: User.find(mentioned_ids[idx]).full_name }
      end
      message.update(lookup: lookup)
    end
  end
end
