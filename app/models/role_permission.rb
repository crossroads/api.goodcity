class RolePermission < ActiveRecord::Base
  belongs_to :role
  belongs_to :permission

  validates :permission_id, uniqueness: { scope: :role_id }
end
