module Api::V1::Stockit
  class LocalOrderSerializer < ApplicationSerializer
    attributes :id, :client_name, :hkid_number

    def hkid_number
      if object.hkid_number.blank?
        ""
      else
        "****#{object.hkid_number[-6..-1]}"
      end
    end

    def hkid_number__sql
      "case when hkid_number is null or hkid_number = '' \
        then '*****' || substr(hkid_number, 5) \
        else '' \
      end"
    end
  end
end
