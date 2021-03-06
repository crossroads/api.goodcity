module Api::V1
  class CompanySerializer < ApplicationSerializer
    embed :ids, include: true
    attributes :id, :name, :crm_id, :created_by_id
  end
end
