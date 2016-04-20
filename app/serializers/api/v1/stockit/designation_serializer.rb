module Api::V1::Stockit
  class DesignationSerializer < ApplicationSerializer
    attributes :status, :created_at
    has_one  :contact, serializer: ContactSerializer
    has_one  :organisation, serializer: OrganisationSerializer
    has_one  :local_order, serializer: LocalOrderSerializer
  end
end
