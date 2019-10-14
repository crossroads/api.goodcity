module Api::V1
  class ComputerAccessorySerializer < ApplicationSerializer
    embed :ids, include: true
    attributes :id, :brand, :model, :serial_number, :country_id, :size,
          :interface, :comp_voltage, :comp_test_status, :updated_by_id
  end
end
