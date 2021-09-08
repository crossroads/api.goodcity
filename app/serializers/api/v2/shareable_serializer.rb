module Api::V2
  class ShareableSerializer < GoodcitySerializer
    # ----------------------------
    #   Attributes
    # ----------------------------

    attributes :id, :resource_type, :resource_id, :allow_listing,
               :expires_at, :created_by_id, :created_at, :updated_at, :public_uid,
               :notes, :notes_zh_tw
  end
end
