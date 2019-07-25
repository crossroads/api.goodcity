module Api::V1
  class RequestedPackageSerializer < ApplicationSerializer
    embed :ids, include: true
    attributes :id, :package_id, :user_id, :is_available

    has_one :package, serializer: PackageSerializer
    has_one :user, serializer: UserSerializer
  end
end
