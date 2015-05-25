module Api::V1
  class GogovanOrderSerializer < ApplicationSerializer
    attributes :id, :booking_id, :status, :price, :driver_name,
      :driver_mobile, :driver_license, :ggv_uuid, :completed_at
  end
end
