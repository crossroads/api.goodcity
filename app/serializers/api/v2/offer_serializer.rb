module Api::V2
  class OfferSerializer
    include FastJsonapi::ObjectSerializer

    # ----------------------------
    #   Attributes
    # ----------------------------

    attributes :id, :language, :state, :origin, :stairs, :parking, :saleable,
      :estimated_size, :notes, :created_by_id, :created_at, :inactive_at,
      :updated_at, :submitted_at, :reviewed_at, :gogovan_transport_id,
      :crossroads_transport_id, :review_completed_at, :received_at,
      :delivered_by, :closed_by_id, :cancelled_at, :received_by_id,
      :company_id, :start_receiving_at, :cancellation_reason_id, :cancel_reason
    
    # ----------------------------
    #   Relationships
    # ----------------------------

    has_many :items
    has_one  :closed_by, serializer: UserSerializer
    has_one  :created_by, serializer: UserSerializer
    has_one  :reviewed_by, serializer: UserSerializer
  end
end
