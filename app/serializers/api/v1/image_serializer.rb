module Api::V1

  class ImageSerializer < ActiveModel::Serializer
    embed :ids, include: true

    attributes :id, :image_url, :thumb_image_url, :favourite, :order, :image_id

    def image_url
      object.image_url
    end

    def thumb_image_url
      object.thumb_image_url
    end

    def image_id
      object.image_id
    end

  end
end
