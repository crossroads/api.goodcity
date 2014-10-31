module Api::V1

  class ItemSerializer < ActiveModel::Serializer
    embed :ids, include: true

    attributes :id, :donor_description, :state, :offer_id, :rejection_other_reason, :saleable,
               :created_at, :updated_at, :image_identifiers, :favourite_image

    has_many :packages, serializer: PackageSerializer
    has_many :messages, serializer: MessageSerializer
    has_many :images,   serializer: ImageSerializer
    has_one  :rejection_reason, serializer: RejectionReasonSerializer
    has_one  :item_type, serializer: ItemTypeSerializer
    has_one  :donor_condition, serializer: DonorConditionSerializer

    def image_identifiers
      object.images.map(&:image_id).join(",")
    end

    def favourite_image
      object.images.select(&:favourite).first.try(:image_id)
    end
  end

end
