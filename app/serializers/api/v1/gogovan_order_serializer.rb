module Api::V1

  class GogovanOrderSerializer < ActiveModel::Serializer

    attributes :id, :booking_id, :status

  end

end
