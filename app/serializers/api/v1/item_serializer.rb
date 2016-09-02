module Api::V1

  class ItemSerializer < ApplicationSerializer
    embed :ids, include: true

    attributes :id, :donor_description, :state, :offer_id, :reject_reason,
      :created_at, :updated_at, :package_type_id, :message_ids, :saleable,
      :rejection_comments, :donor_condition_id, :rejection_reason_id

    has_many :packages, serializer: PackageSerializer
    has_many :images,   serializer: ImageSerializer
    has_one  :package_type, serializer: PackageTypeSerializer
    has_one  :rejection_reason, serializer: RejectionReasonSerializer

    def message_ids
      User.current_user.try(:donor?) ? object.messages.non_private.pluck(:id) : object.messages.pluck(:id)
    end

    def message_ids__sql
      need_private = User.current_user.try(:donor?) ?
        "AND messages.is_private = 'f'" : ""
      "coalesce((select array_agg(messages.id) from messages where
        item_id = items.id #{need_private}), '{}'::int[])"
    end

    def saleable
      object.offer.try(:saleable)
    end

    def saleable__sql
      "(select offers.saleable from offers where offers.id = items.offer_id)"
    end

    def include_message_ids?
      @options[:exclude_messages] != true
    end
  end
end
