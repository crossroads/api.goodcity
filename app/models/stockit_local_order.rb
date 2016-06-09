class StockitLocalOrder < ActiveRecord::Base
  has_one :stockit_designation, as: :detail
end
