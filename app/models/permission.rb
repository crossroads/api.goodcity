class Permission < ApplicationRecord
  include CacheableJson

  has_many :role_permissions
  has_many :roles, through: :role_permissions

  validates :name, uniqueness: true

  scope :visible, -> { where.not(name: 'api-write') }

  def self.names(user_id)
    joins(roles: :active_users).where('user_roles.user_id = (?)', user_id).pluck(:name)
  end
end
