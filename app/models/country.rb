class Country < ActiveRecord::Base
  translates :name
  validates :name_en, presence: true
end
