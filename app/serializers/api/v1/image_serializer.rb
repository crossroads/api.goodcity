module Api::V1
  class ImageSerializer < ApplicationSerializer
    embed :ids, include: true

    attributes :id, :favourite, :cloudinary_id, :item_id, :angle, :package_id, :imageable_type, :imageable_id

    def item_id
      object.imageable_id if object.imageable_type == "Item"
    end

    def package_id
      object.imageable_id if object.imageable_type == "Package"
    end

    def include_package_id?
      !@options[:is_browse_app]
    end
  end
end
