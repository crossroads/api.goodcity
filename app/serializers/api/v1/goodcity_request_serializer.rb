module Api::V1
  class GoodcityRequestSerializer < ApplicationSerializer
    embed :ids, include: true
    attributes :id, :quantity, :description, :code_id
    # Commented below line as it goes into infinite loop of rendering order and request, also don't need to render order again
    # has_one :order, serializer: OrderSerializer, root: :designation, include_order: false
    has_one :package_type, serializer: PackageTypeSerializer, root: :code

    def code_id
      object.package_type_id
    end

    def code_id__sql
      "package_type_id"
    end
  end
end
