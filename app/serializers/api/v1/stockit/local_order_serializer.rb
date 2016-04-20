module Api::V1::Stockit
  class LocalOrderSerializer < ApplicationSerializer
    attributes :id, :detail_type, :detail_id, :client_name, :hkid_number
  end
end
