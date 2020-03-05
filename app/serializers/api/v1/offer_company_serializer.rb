module Api::V1
  class OfferCompanySerializer < ApplicationSerializer
    embed :ids, include: true

    attributes :id, :company_id, :created_by_id, :received_at

    has_one  :created_by, serializer: UserSummarySerializer, root: :user
    has_one  :company, serializer: CompanySerializer
  end
end