module Api::V2
  class ImageSerializer < GoodcitySerializer


    # ----------------------------
    #   Attributes
    # ----------------------------

    attributes :id, :favourite, :cloudinary_id, :angle, :imageable_type, :imageable_id
  end
end
