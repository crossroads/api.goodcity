# frozen_string_literal: true

module Messages
  class Operations < Base
    attr_accessor :message, :subscription, :ids

    def initialize(params)
      @message = params[:message]
      @subscription = params[:subscription]
      @ids = []
      super(params)
    end

    def handle_mentioned_users
      format_message_body
      notify_users
    end

    def subscribe_users_to_message
      obj = message.messageable
      klass = obj.class.name.underscore
      # Add the following users
      #   - Donor / Charity user
      #   - Message sender
      #   - Anyone who has previously replied to offer/order
      #   - Admin users processing the offer/order
      add_related_users(klass, obj)
      ids = ids.flatten.uniq
      remove_unwanted_users(obj)
      add_subscription_for_message
    end

    private

    def add_subscription_for_message
      ids.flatten.compact.uniq.each do |user_id|
        state = user_id == message.sender_id ? 'read' : 'unread' # mark as read for sender
        add_subscription(user_id, state)
      end
    end

    # Cases where we subscribe every staff member
    #  - For private messages, subscribe all supervisors ONLY for the first message
    #  - If donor sends a message but no one else is listening, subscribe all reviewers.
    def subscribe_all_staff_for?(klass, obj)
      if is_private
        first_message_to?(klass, obj.id)
      else
        obj&.created_by_id.present? && (ids == [message.sender_id])
      end
    end

    def first_message_to?(klass, id)
      Message.where(is_private: is_private, "#{klass}_id": id).count.eql? 1
    end

    def remove_unwanted_users(obj)
      ids -= [User.system_user.try(:id), User.stockit_user.try(:id)]
      ids -= [obj.try(:created_by_id)] if message.is_private || obj.try('cancelled?')
      ids
    end

    def add_related_users(klass, obj)
      add_sender_creator
      add_public_private_subscibers_to(obj)
      add_admin_user_fields_to(obj)
      add_all_subscribed_staff(klass, obj)
    end

    def add_all_subscribed_staff(klass, obj)
      ids << User.staff.pluck(:id) if subscribe_all_staff_for?(klass, obj)
    end

    def add_sender_creator
      ids << obj&.created_by_id
      ids << obj&.sender_id
    end

    def add_admin_user_fields_to(obj)
      admin_user_fields.each { |field| user_ids << obj.try(field) }
    end

    def add_public_private_subscibers_to(obj)
      ids << public_subscribers_to(obj)
      ids << private_subscribers_to(obj)
    end

    # A public subscriber is defined as :
    #   > Anyone who has a subscription to that record
    def public_subscribers_to(obj)
      Subscription
        .joins(:message)
        .where(subscribable: obj, messages: { is_private: false} )
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
      sanitize(user_ids)
      replace_ids_with_names
    end

    def add_subscriber(user_id, state = 'unread')
      message.subscriptions.create(state: state,
                                   message_id: message.id,
                                   subscribable: message.messageable,
                                   user_id: user_id)
    end

    def admin_user_fields
      %i[reviewed_by_id processed_by_id process_completed_by_id cancelled_by_id
         process_completed_by dispatch_started_by closed_by submitted_by]
    end

    def notify_users
      ids.map do |id|
        add_subscriber(id)
      end
    end

    def fetch_mentioned_user_ids
      message.body.scan(/\[:\d+\]/)
    end

    def sanitize(ids)
      @ids = ids.map { |id| id.match(/\d+/).to_s }
      @ids
    end

    def replace_ids_with_names
      message.body.gsub(/\[:\d+\]/) do |id|
        User.find(id.match(/\d+/)).full_name
      end
      message.save
    end
  end
end
