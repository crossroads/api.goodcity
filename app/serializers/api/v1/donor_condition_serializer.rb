module Api::V1

  class DonorConditionSerializer < CachingSerializer
    attributes :id, :name
  end

end
