module Api::V1
  class PackageSetSerializer < ActiveModel::Serializer
    embed :ids, include: true

    attributes :id, :package_type_id, :description

    has_many :packages, serializer: PackageSerializer
  end
end
