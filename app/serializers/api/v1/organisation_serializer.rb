module Api::V1
  class OrganisationSerializer < ApplicationSerializer
    embed :ids, include: true
    has_many :user_profiles, serializer: UserProfileSerializer

    attributes :id, :name_en, :name_zh_tw, :description_en, :description_zh_tw, :registration, :website
  end
end
