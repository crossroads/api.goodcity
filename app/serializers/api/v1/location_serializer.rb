module Api::V1
  class LocationSerializer < ApplicationSerializer
    embed :ids, include: true
    attributes :id, :building, :area, :stockit_id

    has_one :printer
  end
end
