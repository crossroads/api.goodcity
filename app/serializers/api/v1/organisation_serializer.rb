module Api::V1
  class OrganisationSerializer < ApplicationSerializer
    embed :ids, include: true
    has_many :users, serializer: UserSerializer

    attributes :id, :name_en, :name_zh_tw, :description_en, :description_zh_tw, :registration, :website
  end
end
