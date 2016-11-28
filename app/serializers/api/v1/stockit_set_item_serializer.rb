module Api::V1

  class StockitSetItemSerializer < ApplicationSerializer
    embed :ids, include: true

    attributes :id, :description, :code_id
    has_many :inventory_packages, serializer: StockitSetItemPackageSerializer, root: :items
    has_one  :package_type, serializer: PackageTypeSerializer, root: :code

    def code_id
      object.package_type_id
    end

    def code_id__sql
      "items.package_type_id"
    end

    def description
      object.donor_description
    end

    def description__sql
      "items.donor_description"
    end
  end
end
