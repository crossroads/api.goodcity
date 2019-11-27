module Api::V1::FastSerializers
  class Image

    include FastJsonapi::ObjectSerializer

    set_type :image

    attributes :id, :favourite, :cloudinary_id, :item_id, :angle, :package_id

    # module Api::V1
    #   class ImageSerializer < ApplicationSerializer
    #     embed :ids, include: true
    
    #     attributes :id, :favourite, :cloudinary_id, :item_id, :angle, :package_id
    
    #     def item_id
    #       object.imageable_id if object.imageable_type == "Item"
    #     end
    
    #     def item_id__sql
    #       "case when imageable_type = 'Item' then imageable_id end"
    #     end
    
    #     def package_id
    #       object.imageable_id if object.imageable_type == "Package"
    #     end
    
    #     def package_id__sql
    #       "case when imageable_type = 'Package' then imageable_id end"
    #     end
    
    #     def include_package_id?
    #       !@options[:is_browse_app]
    #     end
    #   end
    # end
    

  end
end