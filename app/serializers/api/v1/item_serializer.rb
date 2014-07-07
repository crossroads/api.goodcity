module Api::V1

  class ItemSerializer < ActiveModel::Serializer
    embed :ids, include: true

    attributes :id, :donor_description, :donor_condition, :state, :offer_id,
      :item_type_id, :rejection_reason_id, :rejection_other_reason, :created_at, :updated_at

    has_many :packages, serializer: PackageSerializer
    has_many :messages, serializer: MessageSerializer
    has_many :images,   serializer: ImageSerializer
    has_one  :rejection_reason, serializer: RejectionReasonSerializer

  end

end
