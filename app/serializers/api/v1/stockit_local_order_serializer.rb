module Api::V1
  class StockitLocalOrderSerializer < ApplicationSerializer
    attributes :id, :client_name, :hkid_number, :reference_number,
      :purpose_of_goods

    def hkid_number
      if object.hkid_number.blank?
        ""
      else
        "**#{object.hkid_number[-4..-1]}"
      end
    end
  end
end
