module Api::V1
  class ComputerSerializer < ApplicationSerializer
    embed :ids, include: true
    attributes :id, :brand, :model, :serial_num, :country_id, :size,
          :cpu, :ram, :hdd, :optical, :video, :sound, :lan, :wireless,
          :usb, :comp_voltage, :os, :os_serial_num, :ms_office_serial_num,
          :mar_os_serial_num, :mar_ms_office_serial_num, :updated_by_id
    has_one :package, serializer: StockitItemSerializer
  end
end
