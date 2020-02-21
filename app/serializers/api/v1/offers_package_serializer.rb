module Api::V1
  class OffersPackageSerializer < ApplicationSerializer
    embed :ids, include: true
    attributes :id, :offer_id, :package_id
    has_one :offer, serializer: OfferCompanySerializer
  end
end