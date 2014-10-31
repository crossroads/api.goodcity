module Api::V1

  class MessageSerializer < ActiveModel::Serializer

    embed :ids, include: true

    attributes :id, :body, :state, :sender_id,
      :is_private, :created_at, :updated_at, :offer_id, :item_id

    has_one :sender, serializer: UserSerializer, root: :user

    def state
      current_user = scope || object.sender
      object.try("state").blank? ? object.state_for(current_user) : object.try("state")
    end
  end
end
