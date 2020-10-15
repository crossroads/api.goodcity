class CrossroadsTransport < ApplicationRecord
  include RollbarSpecification

  translates :name
  validates :name_en, presence: true
end
