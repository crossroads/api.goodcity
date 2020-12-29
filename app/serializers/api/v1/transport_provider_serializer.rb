module Api::V1
  class TransportProviderSerializer < ApplicationSerializer
    attributes :id, :name, :logo, :description, :metadata
  end
end
