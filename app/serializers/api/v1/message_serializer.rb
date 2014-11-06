module Api::V1

  class MessageSerializer < ActiveModel::Serializer

    embed :ids, include: true

    attributes :id, :body, :state, :is_private, :created_at,
      :updated_at, :offer_id, :item_id, :for_new_offer

    has_one :sender, serializer: UserSerializer, root: :user

    def for_new_offer
      object.try(:offer).try(:submitted?) || false
    end
  end
end
