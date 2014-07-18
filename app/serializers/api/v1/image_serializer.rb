module Api::V1

  class ImageSerializer < ActiveModel::Serializer
    include CloudinaryHelper

    embed :ids, include: true

    attributes :id, :image_url, :thumb_image_url, :favourite, :order

    def image_url
      cl_image_path(object.image)
    end

    def thumb_image_url
      cl_image_path(object.image, width: 50, height: 50, crop: :fill)
    end
  end
end
