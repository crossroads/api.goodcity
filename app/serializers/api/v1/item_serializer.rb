module Api::V1

  class ItemSerializer < ActiveModel::Serializer
    embed :ids, include: true

    attributes :id, :donor_description, :state, :offer_id, :reject_reason,
      :saleable, :created_at, :updated_at, :item_type_id,
      :rejection_comments, :donor_condition_id, :rejection_reason_id, :message_ids

    has_many :packages, serializer: PackageSerializer
    has_many :images,   serializer: ImageSerializer
    has_one :item_type, serializer: ItemTypeSerializer

    def message_ids
      object.messages.pluck(:id)
    end

    def message_ids__sql
      "coalesce((select array_agg(messages.id) from messages where item_id = items.id), '{}'::int[])"
    end

    def include_message_ids?
      @options[:exclude_messages] != true
    end
  end
end
