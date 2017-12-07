class Organisation < ActiveRecord::Base
  belongs_to :organisation_type
  belongs_to :country
  belongs_to :district
  has_many :organisations_users
  has_many :orders
  has_many :users, through: :organisations_users

  def self.search(search_text)
    where("name_en ILIKE ?", "%#{search_text}%")
  end
end
