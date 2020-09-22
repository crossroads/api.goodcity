module Api::V1
  class ItemSerializer < ApplicationSerializer
    embed :ids, include: true

    attributes :id, :donor_description, :state, :offer_id, :reject_reason,
               :created_at, :updated_at, :package_type_id, :saleable,
               :rejection_comments, :donor_condition_id, :rejection_reason_id

    has_many :packages, serializer: PackageSerializer
    has_many :images,   serializer: ImageSerializer, polymorphic: true
    # default scope will exclude { is_private = true } messages which is what we want
    has_many :messages, serializer: MessageSerializer, polymorphic: true
    has_one  :package_type, serializer: PackageTypeSerializer
    has_one  :rejection_reason, serializer: RejectionReasonSerializer
    has_one  :donor_condition, serializer: DonorConditionSerializer

    def saleable
      object.offer.try(:saleable)
    end

    def include_message_ids?
      @options[:exclude_messages] != true
    end

    def include_attribute?
      !User.current_user.try(:donor?)
    end

    alias include_packages? include_attribute?
    alias include_package_type? include_attribute?
    alias include_rejection_reason_id? include_attribute?
    alias include_rejection_reason? include_attribute?
    alias include_reject_reason? include_attribute?
    alias include_rejection_comments? include_attribute?
  end
end
