module Api::V1
  class ElectricalSerializer < ApplicationSerializer
    embed :ids, include: true
    attributes :id, :brand, :model, :serial_number, :country_id, :standard,
        :voltage, :frequency, :power, :system_or_region, :test_status,
        :tested_on, :updated_by_id
    # has_one :package, serializer: StockitItemSerializer, root: :items
  end
end
