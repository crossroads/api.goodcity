module Api::V1
  class OfferSummarySerializer < ApplicationSerializer
    embed :ids, include: true

    attributes :id, :language, :state, :origin, :stairs, :parking, :saleable,
      :estimated_size, :notes, :created_by_id, :created_at, :inactive_at,
      :updated_at, :submitted_at, :reviewed_at, :gogovan_transport_id,
      :crossroads_transport_id, :review_completed_at, :received_at,
      :delivered_by, :closed_by_id, :cancelled_at, :received_by_id,
      :start_receiving_at, :cancellation_reason_id, :cancel_reason

    has_one  :closed_by, serializer: UserSummarySerializer, root: :user
    has_one  :created_by, serializer: UserSummarySerializer, root: :user
    has_one  :reviewed_by, serializer: UserSummarySerializer, root: :user
    has_one  :received_by, serializer: UserSummarySerializer, root: :user
    has_one  :display_image, serializer: ImageSerializer, root: :images

    def display_image
      object.images.first
    end
  end
end
