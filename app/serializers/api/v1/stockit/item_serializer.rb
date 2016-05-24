module Api::V1::Stockit
  class ItemSerializer < ApplicationSerializer
    embed :ids, include: true
    attributes :id, :description, :quantity, :sent_on, :inventory_number

    has_one :location, serializer: Api::V1::Stockit::LocationSerializer
  end
end
