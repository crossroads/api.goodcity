module Api::V1

  class DonorConditionSerializer < ActiveModel::Serializer
    embed :ids, include: true
    attributes :id, :name
  end

end
