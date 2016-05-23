module Api::V1::Stockit
  class ItemSerializer < ApplicationSerializer
    embed :ids, include: true
    attributes :id, :description, :quantity, :sent_on
  end
end
