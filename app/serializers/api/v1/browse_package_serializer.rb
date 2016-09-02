module Api::V1

  class BrowsePackageSerializer < ApplicationSerializer
    embed :ids, include: true

    has_one :package_type, serializer: PackageTypeSerializer
    has_one :item, serializer: BrowseItemSerializer
    has_one :favourite_image, serializer: ImageSerializer, root: :image

    attributes :id, :quantity, :length, :width, :height, :notes, :item_id,
      :created_at, :updated_at, :package_type_id, :favourite_image_id, :grade,
      :donor_condition_id, :image_id

    def image_id
      object.favourite_image_id
    end

    def image_id__sql
      "packages.favourite_image_id"
    end

    def item_id
      object.set_item_id.present?
    end

    def item_id__sql
      "(COALESCE(set_item_id, item_id))"
    end

  end

end
