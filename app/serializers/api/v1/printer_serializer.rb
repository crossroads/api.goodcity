module Api::V1
  class PrinterSerializer < ApplicationSerializer
    embed :ids, include: true
    attributes :id, :name
  end
end
