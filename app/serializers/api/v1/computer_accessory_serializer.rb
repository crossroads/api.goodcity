module Api::V1
  class ComputerAccessorySerializer < ApplicationSerializer
    embed :ids, include: true
    has_one :country
    attributes :id, :brand, :model, :serial_num, :country_id, :size,
          :interface, :comp_voltage, :comp_test_status, :updated_by_id
  end
end
