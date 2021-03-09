module Api
  module V2
    class OfferSerializer < GoodcitySerializer
      include Api::V2::Concerns::Formats
      # ----------------------------
      #   Attributes
      # ----------------------------

      attributes :id, :language, :state, :origin, :stairs, :parking, :saleable,
                 :estimated_size, :notes, :created_by_id, :created_at, :inactive_at,
                 :updated_at, :submitted_at, :reviewed_at, :gogovan_transport_id,
                 :crossroads_transport_id, :review_completed_at, :received_at,
                 :delivered_by, :closed_by_id, :cancelled_at, :received_by_id,
                 :company_id, :start_receiving_at, :cancellation_reason_id, :cancel_reason

      format :public do
        attribute(:public_uid) { |o| Shareable.public_uid_of(o) }
        attribute(:district_id) { |o| o.try(:created_by).try(:address).try(:district_id) }
        attribute(:public_notes) { |o| Shareable.find_by(resource: o).try(:notes) }
        attribute(:public_notes_zh_tw) { |o| Shareable.find_by(resource: o).try(:notes_zh_tw) }
      end

      # ----------------------------
      #   Relationships
      # ----------------------------

      has_many :items
      has_many :images
      has_many :packages
      has_one  :closed_by, serializer: UserSerializer
      has_one  :created_by, serializer: UserSerializer
      has_one  :reviewed_by, serializer: UserSerializer
    end
  end
end
