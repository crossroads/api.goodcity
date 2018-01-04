module Api::V1
  class OrganisationsUserSerializer < ActiveModel::Serializer
    embed :ids, include: true
    attributes :id, :user_id, :organisation_id, :position
    has_one :user, serializer: UserSerializer
  end
end
