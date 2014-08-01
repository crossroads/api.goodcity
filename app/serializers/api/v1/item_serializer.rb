module Api::V1

  class ItemSerializer < ActiveModel::Serializer
    embed :ids, include: true

    attributes :id, :donor_description, :donor_condition_id, :state, :offer_id,
      :item_type_id, :rejection_reason_id, :rejection_other_reason,
      :created_at, :updated_at, :image_identifiers, :favourite_image

    has_many :packages, serializer: PackageSerializer
    has_many :messages, serializer: MessageSerializer
    has_many :images,   serializer: ImageSerializer
    has_one  :rejection_reason, serializer: RejectionReasonSerializer
    has_one  :item_type, serializer: ItemTypeSerializer
    has_one  :donor_condition, serializer: DonorConditionSerializer

    def image_identifiers
      object.images.pluck(:image).join(',')
    end

    def favourite_image
      object.images.get_favourite.try(:image)
    end
  end

end
