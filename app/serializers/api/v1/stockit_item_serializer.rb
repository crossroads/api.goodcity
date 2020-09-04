module Api::V1
  class StockitItemSerializer < ApplicationSerializer
    embed :ids, include: true

    has_one :package_type, serializer: PackageTypeSerializer, root: :code
    has_many :packages_locations, serializer: PackagesLocationSerializer
    has_one :donor_condition, serializer: DonorConditionSerializer
    has_one :order, serializer: Api::V1::OrderShallowSerializer, root: :designation, include_items: false
    has_many :images, serializer: StockitImageSerializer, polymorphic: true
    has_many :orders_packages, serializer: OrdersPackageSerializer
    has_many :offers_packages, serializer: OffersPackageSerializer
    has_many :package_actions, serializer: PackageActionsSerializer, root: :item_actions
    has_one :storage_type, serializer: StorageTypeSerializer
    has_one :package_set, serializer: PackageSetSerializer::StockFormat

    attributes :id, :length, :width, :height, :weight, :pieces, :notes,
               :inventory_number, :created_at, :updated_at, :item_id, :is_set,
               :grade, :designation_name, :designation_id, :sent_on, :code_id,
               :image_id, :donor_condition_id, :package_set_id, :state,
               :case_number, :allow_web_publish, :received_quantity,
               :detail_type, :detail_id, :storage_type_id, :on_hand_quantity,
               :available_quantity, :designated_quantity, :dispatched_quantity, :location_id,
               :quantity, :expiry_date, :saleable, :value_hk_dollar, :restriction_id, :comment

    # note: Quantity is a deprecated field, used only for backwards compatibility
    def quantity
      object.available_quantity
    end

    def quantity__sql
      "available_quantity"
    end

    def include_package_set?
      @options[:include_package_set]
    end

    def include_images?
      @options[:include_images]
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

    # deprecated
    # Kept for backwards compatibility
    # refer to package_set_id from now on
    def is_set
      false
    end

    # deprecated
    # Kept for backwards compatibility
    # refer to package_set_id from now on
    def is_set__sql
      "false"
    end
  end
end
