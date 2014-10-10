module Api::V1

  class DonorConditionSerializer < ActiveModel::Serializer
    attributes :id, :name
  end

end
