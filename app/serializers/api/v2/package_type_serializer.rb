module Api::V2
  class PackageTypeSerializer < GoodcitySerializer


    # ----------------------------
    #   Attributes
    # ----------------------------

    attributes :id, :code, :other_terms, :visible_in_selects,
      :allow_requests, :allow_pieces, :allow_expiry_date,
      :subform, :allow_box, :allow_pallet, :name,
      :description_en, :description_zh_tw
    
  end
end
