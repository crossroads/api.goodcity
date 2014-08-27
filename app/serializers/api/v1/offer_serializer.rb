module Api::V1

  class OfferSerializer < ActiveModel::Serializer
    embed :ids, include: true

    attributes :id, :language, :state, :collection_contact_name, :origin,
      :collection_contact_phone, :stairs, :parking, :estimated_size, :notes,
      :created_by_id, :created_at, :updated_at, :user_name, :user_phone

    has_many :items, serializer: ItemSerializer
    has_many :messages, serializer: MessageSerializer

    def user_name
      object.created_by.try(:full_name)
    end

    def user_phone
      object.created_by.mobile.slice!(4..-1)
    end

  end

end
