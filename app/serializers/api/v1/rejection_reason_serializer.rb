module Api::V1

  class RejectionReasonSerializer < CachingSerializer
    embed :ids, include: true
    attributes :id, :name
  end

end
