module Api::V1::Stockit
  class LocationSerializer < ApplicationSerializer
    embed :ids, include: true
    attributes :id, :area, :building
  end
end
