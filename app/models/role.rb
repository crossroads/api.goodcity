class Role < ActiveRecord::Base
  has_many :user_roles
  has_many :users, through: :user_roles
  has_many :role_permissions
  has_many :permissions, through: :role_permissions
end
