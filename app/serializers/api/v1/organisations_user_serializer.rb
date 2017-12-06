module Api::V1
  class OrganisationsUserSerializer < ActiveModel::Serializer
    embed :ids, include: true
    attributes :id, :user_id, :organisation_id, :role
    has_one :organisation, serializer: OrganisationSerializer
    has_one :user, serializer: UserSerializer
  end
end
