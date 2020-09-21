class Role < ActiveRecord::Base
  include CacheableJson

  validates :name, uniqueness: true

  has_many :user_roles
  has_many :users, through: :user_roles

  has_many :active_user_roles, -> { where("expires_at IS NULL OR expires_at >= ?", Time.current) },
            class_name: "UserRole"
  has_many :active_users, class_name: "User", through: :active_user_roles, source: "user"

  has_many :role_permissions, dependent: :destroy
  has_many :permissions, through: :role_permissions

  scope :visible, ->{ where.not(name: 'api-write') }
  scope :allowed_roles, ->(level) { where("level <= ?", level) }

  def grant(user)
    user.roles << self unless user.roles.include?(self)
  end

  def snake_name
    name.parameterize.underscore
  end

  class << self
    #
    # The empty "null" role can be used to represent users with no roles
    #
    # @return [Role] a null role
    #
    def null_role
      Role.new(name: 'null').freeze
    end
  end
end
