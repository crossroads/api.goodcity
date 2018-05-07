module Api::V1
  class OfferSerializer < ApplicationSerializer
    include FastJsonapi::ObjectSerializer
    include SerializeTimeValue

    embed :ids, include: true

    attributes :id, :language, :state, :origin, :stairs, :parking, :saleable,
      :estimated_size, :notes, :created_by_id, :created_at, :inactive_at,
      :updated_at, :submitted_at, :reviewed_at, :gogovan_transport_id,
      :crossroads_transport_id, :review_completed_at, :received_at,
      :delivered_by, :closed_by_id, :cancelled_at, :received_by_id,
      :start_receiving_at, :cancellation_reason_id, :cancel_reason

    has_many :items, serializer: ItemSerializer
    has_many :messages, serializer: MessageSerializer
    belongs_to  :closed_by, serializer: UserSerializer, root: :user
    belongs_to  :created_by, serializer: UserSerializer, root: :user
    belongs_to  :reviewed_by, serializer: UserSerializer, root: :user
    belongs_to  :delivery, serializer: DeliverySerializer
    belongs_to  :gogovan_transport, serializer: GogovanTransportSerializer
    belongs_to  :crossroads_transport, serializer: CrossroadsTransportSerializer
    belongs_to  :cancellation_reason, serializer: CancellationReasonSerializer

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
