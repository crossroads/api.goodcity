class Organisation < ActiveRecord::Base
  belongs_to :organisation_type
  belongs_to :country
  belongs_to :district
  has_many :organisations_users
  has_many :users, through: :organisations_users
end
