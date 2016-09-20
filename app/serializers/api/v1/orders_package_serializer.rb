module Api::V1

  class OrdersPackageSerializer < ApplicationSerializer
    embed :ids, include: true
    attributes :id, :package_id, :order_id, :state, :quantity
  end

end
