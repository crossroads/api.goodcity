class Permission < ActiveRecord::Base
  include CacheableJson

  has_many :role_permissions
  has_many :roles, through: :role_permissions

  validates :name, uniqueness: true

  scope :api_write,  -> { where(name: 'api-write').first }
  scope :reviewer,   -> { where(name: 'Reviewer').first }
  scope :supervisor, -> { where(name: 'Supervisor').first }
  scope :visible,    -> { where.not(name: 'api-write') }

  def self.names(user_id)
    joins(roles: :active_users).where('user_roles.user_id = (?)', user_id).pluck(:name)
  end
end
