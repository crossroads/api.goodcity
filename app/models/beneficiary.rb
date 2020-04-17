class Beneficiary < ActiveRecord::Base
  belongs_to :identity_type
  belongs_to :created_by, class_name: 'User'
  has_one :order

  validates :identity_type_id, :identity_number, :title, :phone_number, presence: true
  validates :first_name, length: { maximum: 50 }, presence: true
  validates :last_name, length: { maximum: 50 }, presence: true
end
