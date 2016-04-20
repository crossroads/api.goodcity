class Stockit::LocalOrder < Stockit::BaseModel
  has_one :designation, :as => :detail
end
