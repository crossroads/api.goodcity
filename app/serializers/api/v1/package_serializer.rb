module Api::V1
  class PackageSerializer < ApplicationSerializer
    embed :ids, include: true

    has_one :package_type, serializer: PackageTypeSerializer
    has_many :images, serializer: ImageSerializer, polymorphic: true
    has_one :item, serializer: BrowseItemSerializer
    has_many :packages_locations, serializer: PackagesLocationSerializer
    has_many :orders_packages, serializer: OrdersPackageSerializer
    has_one :storage_type, serializer: StorageTypeSerializer
    has_one :package_set, serializer: PackageSetSerializer

    attributes :id, :length, :width, :height, :weight, :pieces, :notes,
               :item_id, :state, :received_at, :rejected_at, :inventory_number,
               :created_at, :updated_at, :package_type_id, :designation_id,
               :sent_on, :offer_id, :designation_name, :grade,
               :donor_condition_id, :received_quantity, :allow_web_publish,
               :detail_type, :detail_id, :on_hand_quantity, :available_quantity,
               :designated_quantity, :dispatched_quantity, :quantity,
               :favourite_image_id, :saleable, :value_hk_dollar, :package_set_id,
               :on_hand_boxed_quantity, :on_hand_palletized_quantity,
               :notes_zh_tw

    # note: Quantity is a deprecated field, used only for backwards compatibility
    def quantity
      object.available_quantity
    end

    def designation_id
      object.order_id
    end

    def is_browse_app?
      @options[:is_browse_app] || @options[:browse_order]
    end

    def not_browse_app?
      !is_browse_app?
    end

    def sent_on
      object.stockit_sent_on
    end

    def include_orders_packages?
      @options[:include_orders_packages]
    end

    def include_package_set?
      @options[:include_package_set]
    end

    def include_packages_locations?
      @options[:include_packages_locations]
    end

    %w[include_item? include_stockit_sent_on?
      include_order_id?].each do |method|
      alias_method method.to_sym, :is_browse_app?
    end

    %w[include_state? include_received_at? include_rejected_at?
       include_designation_id? include_sent_on?
       include_offer_id? include_designation_name?
       include_received_quantity?].each do |method|
      alias_method method.to_sym, :not_browse_app?
    end
  end
end
