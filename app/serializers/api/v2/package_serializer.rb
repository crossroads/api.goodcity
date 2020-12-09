module Api::V2
  class PackageSerializer
    include FastJsonapi::ObjectSerializer

    # ----------------------------
    #   Attributes
    # ----------------------------

    attributes :id, :length, :width, :height, :weight, :pieces, :notes,
      :item_id, :state, :received_at, :rejected_at, :inventory_number,
      :created_at, :updated_at, :package_type_id,
      :offer_id, :grade, :donor_condition_id, :received_quantity,
      :allow_web_publish, :detail_type, :detail_id, :on_hand_quantity,
      :available_quantity, :designated_quantity, :dispatched_quantity,
      :favourite_image_id, :saleable, :value_hk_dollar, :package_set_id,
      :on_hand_boxed_quantity, :on_hand_palletized_quantity,
      :notes_zh_tw
    
    # ----------------------------
    #   Relationships
    # ----------------------------

    has_one :package_type
    has_many :images
    has_one :item

  end
end
