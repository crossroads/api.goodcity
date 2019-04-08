module Api::V1
  class OrganisationsUserSerializer < ActiveModel::Serializer
    embed :ids, include: true
    attributes :id, :user_id, :organisation_id, :position, :preferred_contact_number
    has_one :user, serializer: UserSerializer
    has_one :organisation, serializer: OrganisationWithoutOrderSerializer
  end
end
