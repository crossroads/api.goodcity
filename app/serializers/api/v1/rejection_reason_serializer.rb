module Api::V1

  class RejectionReasonSerializer < ActiveModel::Serializer
    embed :ids, include: true
    attributes :id, :name
  end

end
