module Api::V1
  class StockitLocalOrderSerializer < ApplicationSerializer
    attributes :id, :client_name, :hkid_number, :reference_number

    def hkid_number
      if object.hkid_number.blank?
        ""
      else
        "****#{object.hkid_number[-4..-1]}"
      end
    end

    def hkid_number__sql
      "case when hkid_number is null or hkid_number = '' \
        then '*****' || substr(hkid_number, 4) \
        else '' \
      end"
    end
  end
end
