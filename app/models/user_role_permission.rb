class UserRolePermission < ActiveRecord::Base
  belongs_to :role
  belongs_to :permission
  belongs_to :user
end
