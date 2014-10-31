module Api::V1

  class MessageSerializer < ActiveModel::Serializer

    embed :ids, include: true

    attributes :id, :body, :state, :is_private, :created_at,
      :updated_at, :offer_id, :item_id

    has_one :sender, serializer: UserSerializer, root: :user

    def state
      object.state || object.state_for(current_user)
    end

  end
end
