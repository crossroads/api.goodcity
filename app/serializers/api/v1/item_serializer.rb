module Api::V1

  class ItemSerializer < ActiveModel::Serializer
    embed :ids, include: true

    attributes :id, :donor_description, :state, :offer_id, :reject_reason,
      :saleable, :created_at, :updated_at, :item_type_id,
      :rejection_comments, :donor_condition_id, :rejection_reason_id

    has_many :packages, serializer: PackageSerializer
    has_many :messages, serializer: MessageSerializer
    has_many :images,   serializer: ImageSerializer
    has_one :item_type, serializer: ItemTypeSerializer

  end

end
