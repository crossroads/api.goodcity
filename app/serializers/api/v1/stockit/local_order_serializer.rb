module Api::V1::Stockit
  class LocalOrderSerializer < ApplicationSerializer
    attributes :id, :client_name, :hkid_number
  end
end
