module Api::V1
  class StockitContactSerializer < ApplicationSerializer
    attributes :id, :first_name, :last_name, :mobile_phone_number, :phone_number
  end
end

