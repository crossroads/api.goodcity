module Api::V1

  class ItemSerializer < ActiveModel::Serializer
    embed :ids, include: true

    attributes :id, :donor_description, :donor_condition_id, :state, :offer_id,
      :item_type_id, :rejection_reason_id, :rejection_other_reason, :saleable,
      :created_at, :updated_at, :image_identifiers, :favourite_image

    has_many :packages, serializer: PackageSerializer
    has_many :messages, serializer: MessageSerializer
    has_many :images,   serializer: ImageSerializer
    has_one  :rejection_reason, serializer: RejectionReasonSerializer
    has_one  :item_type, serializer: ItemTypeSerializer
    has_one  :donor_condition, serializer: DonorConditionSerializer

    def image_identifiers
      # This can take advantage of eager loaded images but sacrifices 'separation of concerns'
      # object.images.map(&:image_id).join(',')
      object.images.image_identifiers.join(',')
    end

    def favourite_image
      # This can take advantage of eager loaded images but sacrifices 'separation of concerns'
      # object.images.select(&:favourite).first.try(:image_id)
      object.images.favourites.image_identifiers.first
    end
  end

end
