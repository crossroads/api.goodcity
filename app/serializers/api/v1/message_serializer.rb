module Api::V1

  class MessageSerializer < ApplicationSerializer
    include SerializeTimeValue

    embed :ids, include: true

    attributes :id, :body, :state, :is_private, :created_at,
      :updated_at, :offer_id, :item_id

    has_one :sender, serializer: UserSerializer, root: :user

    def state
      if object.state_value.present?
        object.state_value
      elsif current_user.nil?
        "never-subscribed"
      else
        object.subscriptions.where(user_id: current_user.id).pluck(:state).first
      end
    end

    def state__sql
      if object.state_value.present?
        "'#{object.state_value}'"
      elsif current_user.nil?
        "'never-subscribed'"
      else
        state_query =
          "select state
           from subscriptions s
           where s.message_id = messages.id and s.user_id = #{current_user.id}"

        "CASE
           WHEN EXISTS(#{state_query})
           THEN (#{state_query})
           ELSE 'never-subscribed'
         END"
      end
    end

  end
end
