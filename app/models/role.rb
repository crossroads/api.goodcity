class Role < ApplicationRecord
  include CacheableJson

  validates :name, uniqueness: true

  has_many :user_roles
  has_many :users, through: :user_roles

  has_many :active_user_roles, -> { where("expiry_date IS NULL OR expiry_date >= ?", Time.now.in_time_zone) },
            class_name: "UserRole"
  has_many :active_users, class_name: "User", through: :active_user_roles, source: "user"

  has_many :role_permissions, dependent: :destroy
  has_many :permissions, through: :role_permissions

  scope :visible, ->{ where.not(name: 'api-write') }
  scope :allowed_roles, ->(level) { where("level <= ?", level) }

  def grant(user)
    user.roles << self unless user.roles.include?(self)
  end
end
