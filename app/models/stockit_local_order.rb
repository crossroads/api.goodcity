class StockitLocalOrder < ActiveRecord::Base
  has_one :order, as: :detail
end
