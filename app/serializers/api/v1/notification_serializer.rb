module Api::V1
  class NotificationSerializer < MessageSerializer

    attributes :unread_count

    def unread_count
      record = Message.unscoped.select("count(subscriptions.state)")
        .joins("INNER JOIN subscriptions on messages.id = subscriptions.message_id")
        .where(
          subscriptions: {state: "unread", user_id: User.current_user.id},
          messages: {
            messageable_id: object.messageable_id,
            messageable_type: object.messageable_type,
            is_private: object.is_private,
          },
        )
        .group("messages.messageable_type, messages.messageable_id, messages.is_private")

      record[0] && record[0]["count"]
    end

    def unread_count__sql
      # This method is triggered when message record is created
      # For new message, object.messageable_id and object.messageable_type values
      # are always evaluated to nil. Hence set unread_count to zero.
      "0"
    end
  end
end
