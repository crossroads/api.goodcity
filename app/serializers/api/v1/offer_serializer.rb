module Api::V1

  class OfferSerializer < ActiveModel::Serializer
    embed :ids, include: true

    attributes :id, :language, :state, :collection_contact_name, :collection_contact_phone,
      :origin, :stairs, :parking, :estimated_size, :notes, :created_by_id, :created_at, :updated_at

    has_many :items, serializer: ItemSerializer
    has_many :messages, serializer: MessageSerializer
  end

end
