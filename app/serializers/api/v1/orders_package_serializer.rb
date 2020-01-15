module Api::V1
  class OrdersPackageSerializer < ApplicationSerializer
    embed :ids, include: true
    attributes :id, :package_id, :order_id, :state, :quantity, :dispatched_quantity, :sent_on, :designation_id, :item_id, :created_at, :allowed_actions

    has_one :package, serializer: PackageSerializer

    def designation_id
      object.order_id
    end

    def designation_id__sql
      "order_id"
    end

    def item_id
      object.package_id
    end

    def item_id__sql
      "package_id"
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
  end
end
