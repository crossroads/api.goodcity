class StockitLocalOrder < ApplicationRecord
  has_one :order, as: :detail
end
