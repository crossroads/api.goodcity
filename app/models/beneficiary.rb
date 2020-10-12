class Beneficiary < ApplicationRecord
  belongs_to :identity_type
  belongs_to :created_by, class_name: 'User'
  has_one :order

  validates :identity_type_id, :identity_number, :title, presence: true
  validates :first_name, length: { maximum: 50 }, presence: true
  validates :last_name, length: { maximum: 50 }, presence: true
  validates :phone_number, length: { is: 12 }, presence: true

  before_destroy :unlink_orders

  private

  def unlink_orders
    Order.where(beneficiary_id: id).update_all(beneficiary_id: nil)
  end
end