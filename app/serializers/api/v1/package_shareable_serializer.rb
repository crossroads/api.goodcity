module Api::V1
  class PackageShareableSerializer < ApplicationSerializer
    embed :ids, include: true
    has_many :images, serializer: ImageSerializer, polymorphic: true

    attributes :id, :state, :offer_id, :is_shared, :sharing_expires_at

    def is_shared
      Shareable.non_expired.find_by(resource: object).present?
    end

    def sharing_expires_at
      (Shareable.find_by(resource: object).presence)&.expires_at
    end

  end
end
