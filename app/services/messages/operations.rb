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
      add_related_users(obj)
      ids = ids.flatten.uniq
    end

    private

    def add_related_users(obj)
      add_sender_creator
      add_public_private_subscibers_to(obj)
      add_admin_user_fields_to(obj)
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

    def add_subscriber(user_id)
      message.subscriptions.create(state: 'unread',
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
