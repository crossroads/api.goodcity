module Api::V1
  class OrganisationsUserSerializer < ActiveModel::Serializer
    embed :ids, include: true
    attributes :id, :user_id, :gc_organisation_id, :position

    has_one :user, serializer: UserSerializer

    def gc_organisation_id
      object.organisation_id
    end

    def gc_organisation_id__sql
      "organisation_id"
    end
  end
end
