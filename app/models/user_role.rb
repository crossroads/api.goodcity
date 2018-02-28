class UserRole < ActiveRecord::Base
  belongs_to :user
  belongs_to :role

  def self.create_user_role(user_id, role_id)
    UserRole.create(user_id: user_id, role_id: role_id)
  end
end
