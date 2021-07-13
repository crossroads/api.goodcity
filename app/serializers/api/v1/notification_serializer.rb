module Api::V1
  class NotificationSerializer < MessageSerializer
    attributes :unread_count
    attributes :shareable_public_id

    def shareable_public_id
      if object.messageable_type == 'OfferResponse'
        Shareable.find_by(resource_id: object.messageable.offer_id, resource_type: 'Offer').try(:public_uid)
      end
    end

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
