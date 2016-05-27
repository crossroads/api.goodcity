class Stockit::Item < Stockit::BaseModel
  belongs_to :designation
  belongs_to :image
  belongs_to :location

  scope :latest, -> { order('id desc') }
  scope :exclude_designated, ->(designation_id) {
    where("designation_id <> ?", designation_id)
  }

  def self.search(search_text)
    where("inventory_number LIKE :query", query: "%#{search_text}%")
  end

end
