class Electrical < ActiveRecord::Base
  has_paper_trail class_name: 'Version'

  belongs_to :country
  has_one :package, as: :detail, dependent: :destroy
end
