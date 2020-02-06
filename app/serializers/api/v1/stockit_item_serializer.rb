module Api::V1
  class StockitItemSerializer < ApplicationSerializer
    embed :ids, include: true

    has_one :package_type, serializer: PackageTypeSerializer, root: :code
    has_many :packages_locations, serializer: PackagesLocationSerializer
    has_one :donor_condition, serializer: DonorConditionSerializer
    has_one :order, serializer: Api::V1::OrderShallowSerializer, root: :designation, include_items: false
    has_one :set_item, serializer: Api::V1::StockitSetItemSerializer, include_items: false
    has_many :images, serializer: StockitImageSerializer
    has_many :orders_packages, serializer: OrdersPackageSerializer
    has_one :storage_type, serializer: StorageTypeSerializer

    attributes :id, :quantity, :length, :width, :height, :weight, :pieces, :notes,
      :inventory_number, :created_at, :updated_at, :item_id, :is_set, :grade,
      :designation_name, :designation_id, :sent_on, :code_id, :image_id,
      :donor_condition_id, :set_item_id, :has_box_pallet, :case_number,
      :allow_web_publish, :received_quantity, :detail_type, :detail_id, :storage_type_id,
      :added_quantity, :in_hand_quantity

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

    def include_added_quantity?
      @options[:include_added_quantity]
    end

    def include_in_hand_quantity?
      @options[:include_in_hand_quantity]
    end

    def in_hand_quantity
      object.total_in_hand_quantity
    end

    def in_hand_quantity__sql
      "select sum(quantity) from packages_inventories where package_id = #{object.id}"
    end

    def added_quantity
      object.quantity_in_a_box
    end

    def added_quantity__sql
      "select sum(quantity) from packages_inventories where package_id = #{object.id} and packages_inventories.action in ('pack', 'unpack')"
    end

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
