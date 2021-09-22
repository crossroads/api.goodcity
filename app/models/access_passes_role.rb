class AccessPassesRole < ApplicationRecord
  belongs_to :access_pass
  belongs_to :role

  ALOWED_ROLES = [Role::ROLE_NAMES[:stock_fulfilment], Role::ROLE_NAMES[:order_fulfilment]]
  ALOWED_ROLES_IDS = ALOWED_ROLES.map {|role| Role.find_by(name: role).try(:id) }

  validates :role_id, inclusion: { in: ALOWED_ROLES_IDS }, allow_nil: false
end
