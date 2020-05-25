# frozen_string_literal: true

module Messages
  class Operations < Base
    attr_accessor :message, :ids

    def initialize(params)
      @message = params[:message]
      @ids = []
      super(params.merge(messageable: @message.messageable))
    end

    def handle_mentioned_users
      format_message_body
      notify_users unless ids.empty?
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
        first_message_to?(obj)
      else
        obj&.created_by_id.present? && (ids.compact.uniq == [message.sender_id])
      end
    end

    def first_message_to?(obj)
      Message.where(is_private: message.is_private, messageable: message.messageable).count.eql? 1
    end

    def remove_unwanted_users(obj)
      @ids -= [User.system_user.try(:id), User.stockit_user.try(:id)]
      @ids -= [obj.try(:created_by_id)] if message.is_private || obj.try('cancelled?')
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
      user_ids = fetch_mentioned_user_ids
      return if user_ids.empty?

      sanitize(user_ids)
      add_lookup
    end

    def add_subscriber(user_id, state)
      message.subscriptions.create(state: state,
                                   message_id: message.id,
                                   subscribable: messageable,
                                   user_id: user_id)
    end

    def admin_user_fields
      %i[reviewed_by_id processed_by_id process_completed_by_id cancelled_by_id
         process_completed_by dispatch_started_by closed_by submitted_by]
    end

    def notify_users
      ids.map do |id|
        add_subscriber(id, 'unread')
      end
    end

    def fetch_mentioned_user_ids
      message.body.scan(/\[:\d+\]/)
    end

    def sanitize(ids)
      @ids = ids.map { |id| id.match(/\d+/).to_s }
    end

    def add_lookup
      lookup = []
      ids.map do |id|
        lookup << { type: 'User', id: id, display_name: User.find(id).full_name }
      end
      message.update(lookup: lookup)
    end
  end
end
