class Request < ActiveRecord::Base
  has_paper_trail class_name: 'Version'
  belongs_to :package_type
  belongs_to :order
  belongs_to :created_by, class_name: 'User'
  validates  :quantity,  numericality: { greater_than_or_equal_to: 1 }
end
