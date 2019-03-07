module Api::V1
  class OfferSummarySerializer < ApplicationSerializer
    # include SerializeTimeValue

    embed :ids, include: true

    attributes :id, :language, :state, :origin, :stairs, :parking, :saleable,
      :estimated_size, :notes, :created_by_id, :created_at, :inactive_at,
      :updated_at, :submitted_at, :reviewed_at, :gogovan_transport_id,
      :crossroads_transport_id, :review_completed_at, :received_at,
      :delivered_by, :closed_by_id, :cancelled_at, :received_by_id,
      :start_receiving_at, :cancellation_reason_id, :cancel_reason

    has_one  :closed_by, serializer: UserSerializer, root: :user
    has_one  :created_by, serializer: UserSerializer, root: :user
    has_one  :reviewed_by, serializer: UserSerializer, root: :user
    has_one  :display_image, serializer: ImageSerializer, root: :images

    def display_image
      Image.where(imageable: offer.items).limit(1).first
    end
      it_with_images = object.items.detect { |it| it.images.any? }
      return nil unless it_with_images
      return it_with_images.images.first
    end
  end
end
