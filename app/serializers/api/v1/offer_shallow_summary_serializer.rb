module Api::V1
  class OfferShallowSummarySerializer < ApplicationSerializer
    embed :ids, include: true

    attributes :id, :company_id, :created_by_id

    has_one  :created_by, serializer: UserSummarySerializer, root: :user
    has_one  :company, serializer: CompanySerializer
  end
end