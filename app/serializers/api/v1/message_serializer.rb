module Api::V1
  class MessageSerializer < ApplicationSerializer
    embed :ids, include: true

    attributes :id, :body, :state, :is_private, :created_at,
      :updated_at, :offer_id, :item_id, :designation_id, :order_id

    has_one :sender, serializer: UserSerializer, root: :user

    def designation_id
      object.order_id
    end

    def designation_id__sql
      'order_id'
    end

    def state
      if object.state_value.present?
        object.state_value
      elsif User.current_user.nil?
        "never-subscribed"
      else
        object.subscriptions.where(user_id: User.current_user.id).pluck(:state).first
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
