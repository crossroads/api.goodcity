module Api::V1

  class OfferSerializer < ApplicationSerializer
    include SerializeTimeValue

    embed :ids, include: true

    attributes :id, :language, :state, :origin, :stairs, :parking,
      :estimated_size, :notes, :created_by_id, :created_at,
      :updated_at, :submitted_at, :reviewed_at, :gogovan_transport_id,
      :crossroads_transport_id, :review_completed_at, :received_at,
      :delivered_by, :closed_by_id, :cancelled_at, :received_by_id,
      :start_receiving_at

    has_many :items, serializer: ItemSerializer
    has_many :messages, serializer: MessageSerializer
    has_one  :created_by, serializer: UserSerializer, root: :user
    has_one  :reviewed_by, serializer: UserSerializer, root: :user
    has_one  :delivery, serializer: DeliverySerializer
    has_one  :gogovan_transport, serializer: GogovanTransportSerializer
    has_one  :crossroads_transport, serializer: CrossroadsTransportSerializer

    def include_messages?
      return false unless goodcity_user?
      @options[:exclude_messages] != true
    end

    def goodcity_user?
      User.current_user.present?
    end

    alias_method :include_reviewed_by?, :goodcity_user?
    alias_method :include_gogovan_transport?, :goodcity_user?
    alias_method :include_crossroads_transport?, :goodcity_user?

  end
end
