class Permission < ActiveRecord::Base
  include CacheableJson

  has_many :users, inverse_of: :permission
  has_many :role_permissions
  has_many :roles, through: :role_permissions

  scope :api_write,  ->{ where(name: 'api-write').first }
  scope :reviewer,   ->{ where(name: 'Reviewer').first }
  scope :supervisor, ->{ where(name: 'Supervisor').first }
  scope :visible,    ->{ where.not(name: 'api-write') }
  scope :charity,    ->{ where(name: 'Charity').first }
end
