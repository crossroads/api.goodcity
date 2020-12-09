module Api::V2
  class ItemSerializer
    include FastJsonapi::ObjectSerializer

    # ----------------------------
    #   Attributes
    # ----------------------------

    attributes :id, :donor_description, :state, :offer_id, :reject_reason,
      :created_at, :updated_at, :package_type_id, :rejection_comments,
      :donor_condition_id, :rejection_reason_id
    
    # ----------------------------
    #   Relationships
    # ----------------------------

    has_one   :offer
    has_many  :packages
    has_many  :images,   serializer: ImageSerializer, polymorphic: true
  end
end
