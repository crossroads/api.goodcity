
module Api::V1
  class BeneficiarySerializer < ApplicationSerializer
    embed :ids, include: true
    attributes  :id,
                :identity_type_id,
                :identity_number,
                :created_by_id,
                :title,
                :first_name,
                :last_name,
                :phone_number

    has_one  :identity_type, serializer: IdentityTypeSerializer
  end
end
