module Api::V1

  class StockitItemSerializer < ApplicationSerializer
    embed :ids, include: true

    has_one :package_type, serializer: PackageTypeSerializer, root: :code
    has_one :location, serializer: LocationSerializer
    has_one :donor_condition, serializer: DonorConditionSerializer
    has_one :order, serializer: Api::V1::OrderSerializer, root: :designation, include_items: false
    has_one :set_item, serializer: Api::V1::StockitSetItemSerializer, include_items: false
    has_many :images, serializer: StockitImageSerializer
    has_many :orders_packages, serializer: OrdersPackageSerializer

    attributes :id, :quantity, :length, :width, :height, :notes, :location_id,
      :inventory_number, :created_at, :updated_at, :item_id, :is_set, :grade,
      :designation_name, :designation_id, :sent_on, :code_id, :image_id,
      :donor_condition_id, :set_item_id, :has_box_pallet, :case_number,
      :allow_web_publish, :received_quantity

    def include_images?
      @options[:include_images]
    end

    def include_set_item?
      !@options[:exclude_stockit_set_item]
    end

    def include_order?
      @options[:include_order]
    end

    alias_method :include_designation_id?, :include_order?

    def designation_id
      object.order_id
    end

    def designation_id__sql
      "order_id"
    end

    def sent_on
      object.stockit_sent_on
    end

    def sent_on__sql
      "stockit_sent_on"
    end

    def code_id
      object.package_type_id
    end

    def code_id__sql
      "packages.package_type_id"
    end

    def image_id
      object.favourite_image_id
    end

    def image_id__sql
      "packages.favourite_image_id"
    end

    def is_set
      object.set_item_id.present?
    end

    def has_box_pallet
      object.box_id.present? || object.pallet_id.present?
    end

    def is_set__sql
      "(CASE WHEN set_item_id IS NOT NULL
        THEN true
        ELSE false
        END)"
    end

    def has_box_pallet__sql
      "(CASE WHEN box_id IS NOT NULL OR pallet_id IS NOT NULL
        THEN true
        ELSE false
        END)"
    end
  end

end
