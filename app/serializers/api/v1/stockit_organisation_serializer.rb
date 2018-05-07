module Api::V1
  class StockitOrganisationSerializer < ApplicationSerializer
    include FastJsonapi::ObjectSerializer
    attributes :id, :name
  end
end
