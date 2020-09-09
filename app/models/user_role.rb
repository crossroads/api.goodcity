class UserRole < ActiveRecord::Base
  has_paper_trail class_name: 'Version'

  belongs_to :user
  belongs_to :role

  validates :role_id, uniqueness: { scope: :user_id }
  before_save :set_expiry_date_time, if: lambda { expiry_date.present? }

  def self.create_user_role(user_id, role_id)
    create(user_id: user_id, role_id: role_id)
  end

  def set_expiry_date_time
    self.expiry_date = self.expiry_date.change(hour: 20)
  end
end
