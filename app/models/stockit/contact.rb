class Stockit::Contact < Stockit::BaseModel
  belongs_to :organisation
  belongs_to :country
end
