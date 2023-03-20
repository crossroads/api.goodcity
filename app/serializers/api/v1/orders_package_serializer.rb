module Api::V1
  class OrdersPackageSerializer < ApplicationSerializer
    embed :ids, include: true
    attributes :id, :package_id, :order_id, :state, :quantity,
               :dispatched_quantity, :sent_on, :designation_id,
               :item_id, :created_at, :allowed_actions, :shipping_number, :updated_by_id

    has_one :updated_by, serializer: UserSummarySerializer, root: :user
    has_one :package, serializer: PackageShallowSerializer
    has_one :order, serializer: OrderShallowSerializer, root: 'designation'
    has_many :packages_locations, serializer: PackagesLocationSerializer

    def designation_id
      object.order_id
    end

    def item_id
      object.package_id
    end

    def packages_locations
      object.package.packages_locations
    end

    def include_packages_locations?
      # if cancelling or dispatching then location qty is affected
      @options[:include_packages_locations]
    end

    def allowed_actions
      object.allowed_actions
    end

    def include_allowed_actions?
      @options[:include_allowed_actions]
    end

    def include_package?
      @options[:include_package]
    end

    def include_order?
      @options[:include_order]
    end
  end
end
