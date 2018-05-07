module Api::V1
  class StockitContactSerializer < ApplicationSerializer
    include FastJsonapi::ObjectSerializer
    attributes :id, :first_name, :last_name, :mobile_phone_number, :phone_number
  end
end

