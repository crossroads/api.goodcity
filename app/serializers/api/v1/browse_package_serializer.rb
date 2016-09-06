module Api::V1

  class BrowsePackageSerializer < ApplicationSerializer
    embed :ids, include: true

    has_one :package_type, serializer: PackageTypeSerializer
    has_one :item, serializer: BrowseItemSerializer
    has_many :images, serializer: StockitImageSerializer

    attributes :id, :quantity, :length, :width, :height, :notes, :item_id,
      :created_at, :updated_at, :package_type_id, :grade,
      :donor_condition_id

    def item_id
      object.set_item_id.present?
    end

    def item_id__sql
      "(COALESCE(set_item_id, item_id))"
    end

  end

end
