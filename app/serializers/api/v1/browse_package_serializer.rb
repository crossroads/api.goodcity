module Api::V1

  class BrowsePackageSerializer < ApplicationSerializer
    embed :ids, include: true

    has_one :package_type, serializer: PackageTypeSerializer
    has_one :item, serializer: BrowseItemSerializer
    has_many :images, serializer: StockitImageSerializer

    attributes :id, :quantity, :length, :width, :height, :notes, :item_id,
      :created_at, :updated_at, :package_type_id, :grade,
      :donor_condition_id, :stockit_sent_on, :order_id

    def item_id
      if object.inventory_number.present?
        object.set_item_id
      else
        object.set_item_id || object.item_id
      end
    end

    def item_id__sql
      "(CASE WHEN inventory_number IS NOT NULL
        THEN set_item_id
        ELSE (COALESCE(set_item_id, item_id))
        END)"
    end

  end

end
