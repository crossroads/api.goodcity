module Api::V1
  class OfferSummarySerializer < ApplicationSerializer
    embed :ids, include: true

    attributes :id, :state, :created_at, :inactive_at,
               :updated_at, :submitted_at, :reviewed_at, :review_completed_at,
               :received_at, :cancelled_at, :start_receiving_at,
               :submitted_items_count, :accepted_items_count,
               :rejected_items_count,
               :expecting_packages_count, :missing_packages_count,
               :received_packages_count,
               :display_image_cloudinary_id, :notes, :is_shared

    has_one  :closed_by, serializer: UserSummarySerializer, root: :user
    has_one  :created_by, serializer: UserSummarySerializer, root: :user
    has_one  :reviewed_by, serializer: UserSummarySerializer, root: :user
    has_one  :received_by, serializer: UserSummarySerializer, root: :user
    has_one  :delivery, serializer: DeliverySerializer, root: :delivery
    has_many :messages, serializer: MessageSerializer, polymorphic: true
    has_one  :company, serializer: CompanySerializer

    def include_messages?
      return false unless goodcity_user?

      @options[:include_messages] == true
    end

    def display_image_cloudinary_id
      object.images.first.try(:cloudinary_id)
    end

    def is_shared
      Shareable.non_expired.find_by(resource: object).present?
    end

    def submitted_items_count
      object.submitted_items.size
    end

    def accepted_items_count
      object.accepted_items.size
    end

    def rejected_items_count
      object.rejected_items.size
    end

    def expecting_packages_count
      object.expecting_packages.size
    end

    def missing_packages_count
      object.missing_packages.size
    end

    def received_packages_count
      object.received_packages.size
    end

    def goodcity_user?
      User.current_user.present?
    end
  end
end
