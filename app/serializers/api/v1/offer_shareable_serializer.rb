module Api::V1
  class OfferShareableSerializer < ApplicationSerializer
    embed :ids, include: true

    attributes :id, :state, :sharing_expires_at

    has_many :shared_packages, serializer: PackageShareableSerializer, root: "package"

    def sharing_expires_at
      (Shareable.find_by(resource: object).presence)&.expires_at
    end
  end
end
