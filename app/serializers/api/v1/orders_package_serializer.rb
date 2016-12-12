module Api::V1

  class OrdersPackageSerializer < ApplicationSerializer
    embed :ids, include: true
    attributes :id, :package_id, :order_id, :state, :quantity, :sent_on, :designation_id, :item_id

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
  end

end
