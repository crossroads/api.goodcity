module Api::V1
  class OfferResponseSerializer < ApplicationSerializer
    embed :ids, include: true
    attributes :id, :user_id, :offer_id

    has_one :offer, serializer: OfferShareableSerializer
  end
end
