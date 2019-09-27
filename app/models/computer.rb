class Computer < ActiveRecord::Base
  belongs_to :country
  has_one :package, as: :detail, dependent: :destroy
end
