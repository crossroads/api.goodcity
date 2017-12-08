class Country < ActiveRecord::Base
  include RollbarSpecification

  translates :name
  validates :name_en, presence: true
end
