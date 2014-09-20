module Api::V1

  class OfferSerializer < ActiveModel::Serializer
    embed :ids, include: true

    attributes :id, :language, :state, :origin, :stairs, :parking,
      :estimated_size, :notes, :created_by_id, :created_at,
      :updated_at, :submitted_at, :user_name, :user_phone, :user_ids, :delivery_id,
      :reviewed_by_id, :reviewed_at

    has_many :items, serializer: ItemSerializer
    has_many :messages, serializer: MessageSerializer
    has_one  :created_by, serializer: UserSerializer, root: :user
    has_one  :reviewed_by, serializer: UserSerializer, root: :user
    has_one  :delivery, serializer: DeliverySerializer

    def user_name
      object.created_by.try(:full_name)
    end

    def user_phone
      object.created_by.try(:mobile) && object.created_by.mobile.slice!(4..-1)
    end

    def user_ids
      [object.created_by_id, object.reviewed_by_id]
    end

    def delivery_id
      object.delivery.try(:id)
    end
  end

end
