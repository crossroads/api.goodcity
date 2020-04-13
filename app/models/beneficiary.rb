class Beneficiary < ActiveRecord::Base
  belongs_to :identity_type
  belongs_to :created_by, class_name: 'User'
  has_one :order

  validates :first_name, length: { maximum: 50 }
  validates :last_name, length: { maximum: 50 }
end
