
module Api::V1
  class BeneficiarySerializer < ApplicationSerializer
    attributes :id, :identity_type_id, :identity_number, :created_by_id, :title, :first_name,
      :last_name, :phone_number

    has_one  :created_by, serializer: UserSerializer, root: :user
    has_one  :identity_type, serializer: IdentityTypeSerializer, root: :identity_type
  end
end
    