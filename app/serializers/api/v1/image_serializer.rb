module Api::V1

  class ImageSerializer < ActiveModel::Serializer
    include CloudinaryHelper

    embed :ids, include: true

    attributes :id, :image_url, :thumb_image_url, :favourite, :order, :image_id

    def image_url
      image = "v" + object.image
      cl_image_path(image)
    end

    def thumb_image_url
      image = "v" + object.image
      cl_image_path(image, width: 50, height: 50, crop: :fill)
    end

    def image_id
      object.image
    end
  end
end
