module Api::V1::Stockit
  class ItemSerializer < ApplicationSerializer
    embed :ids, include: true
    attributes :id, :description, :quantity, :sent_on, :inventory_number

    has_one :location, serializer: Api::V1::Stockit::LocationSerializer
    has_one :code, serializer: Api::V1::Stockit::CodeSerializer
    has_one :designation, serializer: Api::V1::Stockit::DesignationSerializer

    def include_designation?
      @options[:include_designation]
    end
  end
end
