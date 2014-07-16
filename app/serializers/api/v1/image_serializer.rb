module Api::V1

  class ImageSerializer < ActiveModel::Serializer
    embed :ids, include: true

    attributes :id, :image_url, :thumb_image_url, :standard_image_url, :favourite, :order

    def image_url
      object.image.url
    end

    def thumb_image_url
      object.image.thumbnail.url
    end

    def standard_image_url
      object.image.standard.url
    end
  end
end
