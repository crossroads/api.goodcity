module Api::V1
  class PrinterSerializer < ApplicationSerializer
    embed :ids, include: true
    attributes :id

    has_one :location, serializer: LocationSerializer
  end
end
