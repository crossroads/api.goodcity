# TODO
# turn fields on and off via runtime state (e.g. security permissions)
# nested 

module Api::V1::FastSerializers
  class Package

    include FastJsonapi::ObjectSerializer

    set_type :package

    attributes :id, :quantity, :length, :width, :height, :weight, :pieces, :notes,
               :item_id, :state, :received_at, :rejected_at, :inventory_number,
               :created_at, :updated_at, :package_type_id, :sent_on,
               :offer_id, :designation_name, :grade, :donor_condition_id, :received_quantity,
               :allow_web_publish, :detail_type, :detail_id, :images
    attribute  :sent_on, &:stockit_sent_on
    attribute  :designation_id, &:order_id

    has_many :images, serializer: :image

    # has_one :package_type #, serializer: PackageTypeSerializer
    # has_one :item #, serializer: BrowseItemSerializer
    # has_many :packages_locations #, serializer: PackagesLocationSerializer
    # has_many :orders_packages #, serializer: OrdersPackageSerializer

  end
end

  #   def is_browse_app?
  #     @options[:is_browse_app] || @options[:browse_order]
  #   end

  #   def not_browse_app?
  #     !is_browse_app?
  #   end

  #   def include_orders_packages?
  #     @options[:include_orders_packages]
  #   end

  #   alias_method :include_packages_locations?, :include_orders_packages?

  #   %w[include_item? include_stockit_sent_on?
  #     include_order_id?].each do |method|
  #     alias_method method.to_sym, :is_browse_app?
  #   end

  #   %w[include_state? include_received_at? include_rejected_at?
  #     include_designation_id? include_sent_on?
  #     include_offer_id? include_designation_name?
  #     include_received_quantity?].each do |method|
  #     alias_method method.to_sym, :not_browse_app?
  #   end
  # end
