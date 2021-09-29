class AccessPassesRole < ApplicationRecord
  belongs_to :access_pass
  belongs_to :role

  ALLOWED_ROLES = [Role::ROLE_NAMES[:stock_fulfilment], Role::ROLE_NAMES[:order_fulfilment]]

  validates :role_id, inclusion: { in: Proc.new {  AccessPassesRole.allowed_roles_ids } }, allow_nil: false

  def self.allowed_roles_ids
    Role.where(name: ALLOWED_ROLES).pluck(:id)
  end
end
