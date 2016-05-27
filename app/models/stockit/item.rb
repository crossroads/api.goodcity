class Stockit::Item < Stockit::BaseModel
  belongs_to :designation
  belongs_to :image
  belongs_to :location
  belongs_to :code

  scope :latest, -> { order('id desc') }
  scope :undispatched, -> { where(sent_on: nil) }
  scope :exclude_designated, ->(designation_id) {
    where("designation_id <> ?", designation_id)
  }

  def self.search(search_text)
    where("inventory_number LIKE :query", query: "%#{search_text}%")
  end
end
