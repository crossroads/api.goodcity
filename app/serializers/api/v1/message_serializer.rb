module Api::V1

  class MessageSerializer < ActiveModel::Serializer
    embed :ids, include: true

    attributes :id, :body, :recipient_id, :sender_id,
      :is_private, :created_at, :updated_at

    has_one :sender, serializer: UserSerializer

  end

end
