module Api::V1
  class GoodcityRequestSerializer < ApplicationSerializer
    embed :ids, include: true
    attributes :id, :quantity, :description, :code_id, :item_specifics
    has_one :package_type, serializer: PackageTypeSerializer, root: :code

    def code_id
      object.package_type_id
    end

    def code_id__sql
      "package_type_id"
    end
  end
end
