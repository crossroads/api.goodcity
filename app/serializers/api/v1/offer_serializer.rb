module Api::V1

  class OfferSerializer < ApplicationSerializer
    include SerializeTimeValue

    embed :ids, include: true

    attributes :id, :language, :state, :origin, :stairs, :parking,
      :estimated_size, :notes, :created_by_id, :created_at,
      :updated_at, :submitted_at, :reviewed_at, :gogovan_transport_id,
      :crossroads_transport_id, :review_completed_at, :removed_at,
      :received_at, :delivered_by

    has_many :items, serializer: ItemSerializer
    has_many :messages, serializer: MessageSerializer
    has_one  :created_by, serializer: UserSerializer, root: :user
    has_one  :reviewed_by, serializer: UserSerializer, root: :user
    has_one  :delivery, serializer: DeliverySerializer
    has_one  :gogovan_transport, serializer: GogovanTransportSerializer
    has_one  :crossroads_transport, serializer: CrossroadsTransportSerializer

    def include_messages?
      @options[:exclude_messages] != true
    end

    # Use it to send soft-deleted offers
    def removed_at__sql
      "deleted_at"
    end

    def removed_at
      object.deleted_at
    end
  end
end
