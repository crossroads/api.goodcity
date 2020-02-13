module Api::V1
  class OffersPackageSerializer < ApplicationSerializer
    embed :ids, include: true
    attributes :id, :offer_id, :item_id

    def offer_id
      object.offer_id
    end

    def offer_id__sql
      "offer_id"
    end

    def item_id
      object.package_id
    end

    def item_id__sql
      "package_id"
    end
  end
end