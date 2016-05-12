module Api::V1::Stockit
  class DesignationSerializer < ApplicationSerializer
    embed :ids, include: true
    attributes :status, :created_at, :code, :detail_type, :id, :detail_id,
      :local_order_id

    has_one :contact, serializer: Api::V1::Stockit::ContactSerializer
    has_one :organisation, serializer: Api::V1::Stockit::OrganisationSerializer
    has_one :local_order, serializer: Api::V1::Stockit::LocalOrderSerializer

    def local_order_id
      object.local_order_id
    end

    def local_order_id__sql
      object.local_order_id.blank? ? "null" : "'#{object.local_order_id}'"
    end
  end
end
