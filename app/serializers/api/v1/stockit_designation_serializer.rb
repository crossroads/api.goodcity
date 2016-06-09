module Api::V1
  class StockitDesignationSerializer < ApplicationSerializer
    embed :ids, include: true
    attributes :status, :created_at, :code, :detail_type, :id, :detail_id

    has_one :stockit_contact, serializer: StockitContactSerializer, root: :contact
    has_one :stockit_organisation, serializer: StockitOrganisationSerializer, root: :organisation
    has_one :detail, serializer: StockitLocalOrderSerializer, root: :local_order
    # has_many :items, serializer: Stockit::ItemSerializer
  end
end
