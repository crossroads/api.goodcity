class Stockit::Item < Stockit::BaseModel
  belongs_to :designation
  belongs_to :image
end
