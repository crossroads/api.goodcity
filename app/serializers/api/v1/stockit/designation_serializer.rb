module Api::V1::Stockit
  class DesignationSerializer < ApplicationSerializer
    embed :ids, include: true
    attributes :status, :created_at, :code, :detail_type, :id, :detail_id,
      :local_order_id

    has_one :contact, serializer: Api::V1::Stockit::ContactSerializer
    has_one :organisation, serializer: Api::V1::Stockit::OrganisationSerializer
    has_one :local_order, serializer: Api::V1::Stockit::LocalOrderSerializer
    has_many :items, serializer: Api::V1::Stockit::ItemSerializer

    def local_order_id
      object.local_order_id
    end

    def local_order_id__sql
      "case when detail_type = 'LocalOrder' then detail_id end"
    end
  end
end
