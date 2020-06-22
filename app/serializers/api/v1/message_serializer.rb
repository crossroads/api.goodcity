module Api::V1
  class MessageSerializer < ApplicationSerializer
    embed :ids, include: true
    # Deprication: order_id, offer_id, item_id will be removed
    attributes :id, :body, :state, :is_private, :created_at,
               :updated_at, :messageable_type,
               :messageable_id, :lookup, :offer_id,
               :item_id, :designation_id, :order_id

    has_one :sender, serializer: UserSerializer, root: :user

    def lookup
      object.lookup.to_json
    end

    # Deprication: This will be removed
    def item_id
      object.messageable_type == 'Item' ? object.messageable_id : nil
    end

    def item_id__sql
      "CASE WHEN messageable_type='Item' THEN messageable_id ELSE NULL END"
    end

    # Deprication: This will be removed
    def order_id
      object.messageable_type == 'Order' ? object.messageable_id : nil
    end

    # Deprication: This will be removed
    def designation_id
      object.messageable_type == 'Order' ? object.messageable_id : nil
    end

    def designation_id__sql
      "CASE WHEN messageable_type='Order' THEN messageable_id ELSE NULL END"
    end

    def order_id__sql
      "CASE WHEN messageable_type='Order' THEN messageable_id ELSE NULL END"
    end

    # Deprication: This will be removed
    def offer_id
      object.messageable_type == 'Offer' ? object.messageable_id : nil
    end

    def offer_id__sql
      "CASE WHEN messageable_type='Offer' THEN messageable_id ELSE NULL END"
    end

    def state
      if object.state_value.present?
        object.state_value
      elsif User.current_user.nil?
        "never-subscribed"
      else
        object.subscriptions.where(user_id: User.current_user.id).pluck(:state).first || 'never-subscribed'
      end
    end

    def state__sql
      if object.state_value.present?
        "'#{object.state_value}'"
      elsif User.current_user.nil?
        "'never-subscribed'"
      else
        state_query =
          "select state
           from subscriptions s
           where s.message_id = messages.id and s.user_id = #{User.current_user.id}"

        "CASE
           WHEN EXISTS(#{state_query})
           THEN (#{state_query})
           ELSE 'never-subscribed'
         END"
      end
    end
  end
end
