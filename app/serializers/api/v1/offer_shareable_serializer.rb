module Api::V1
  class OfferShareableSerializer < ApplicationSerializer
    embed :ids, include: true

    attributes :id, :state, :sharing_expires_at, :public_uid

    has_many :shared_packages, serializer: PackageShareableSerializer, root: "package"

    def sharing_expires_at
      (Shareable.find_by(resource: object).presence)&.expires_at
    end

    def public_uid
      (Shareable.find_by(resource: object).presence)&.public_uid
    end
  end
end
