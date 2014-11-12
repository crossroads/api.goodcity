module Api::V1

  class ItemSerializer < ActiveModel::Serializer
    embed :ids, include: true

    attributes :id, :donor_description, :state, :offer_id, :reject_reason,
      :saleable, :created_at, :updated_at, :image_identifiers, :item_type_id,
      :favourite_image, :rejection_comments, :donor_condition_id, :rejection_reason_id

    has_many :packages, serializer: PackageSerializer
    has_many :messages, serializer: MessageSerializer
    has_many :images,   serializer: ImageSerializer

    def image_identifiers
      object.images.map(&:image_id).join(",")
    end

    def favourite_image
      object.images.select(&:favourite).first.try(:image_id)
    end
  end

end
