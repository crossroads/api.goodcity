class Territory < ActiveRecord::Base
  has_many :districts
  validates :name, presence: true
end
