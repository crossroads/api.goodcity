module Api::V1
  class PrinterSerializer < ApplicationSerializer
    embed :ids, include: true
    attributes :id

    belongs_to :location
  end
end
