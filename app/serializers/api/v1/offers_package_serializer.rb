module Api::V1
  class OffersPackageSerializer < ApplicationSerializer
    embed :ids, include: true
    attributes :id, :offer_id, :package_id
    has_one :offer, serializer: OfferShallowSummarySerializer

    def offer_id
      object.offer_id
    end

    def offer_id__sql
      "offer_id"
    end

    def package_id
      object.package_id
    end

    def package_id__sql
      "package_id"
    end
  end
end