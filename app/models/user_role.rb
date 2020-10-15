class UserRole < ApplicationRecord
  has_paper_trail versions: { class_name: 'Version' }

  belongs_to :user
  belongs_to :role

  validates :role_id, uniqueness: { scope: :user_id }

  def self.create_user_role(user_id, role_id)
    create(user_id: user_id, role_id: role_id)
  end
end
