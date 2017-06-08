module Api::V1
  class OrganisationsUserSerializer < ActiveModel::Serializer
    embed :ids, include: true
    attributes :id
    has_one :organisation, serializer: OrganisationSerializer
    has_one :user, serializer: UserSerializer
  end
end
