module Api::V1
  class NotificationSerializer < MessageSerializer
    attributes :unread_count

    def unread_count
      record = Message.select("count(subscriptions.state)")
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
  end
end
