module Api::V1
  class PackageSetSerializer < ActiveModel::Serializer
    embed :ids, include: true

    attributes :id, :package_type_id, :description

    has_many :packages, serializer: PackageSerializer, include_package_set: false

    def include_packages?
      !@options[:exclude_set_packages]
    end

    class StockFormat < PackageSetSerializer
      has_many :packages, serializer: StockitItemSerializer, include_images: true, include_package_set: false, root: :items
    end
  end
end
