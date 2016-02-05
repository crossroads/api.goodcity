class Permission < ActiveRecord::Base
  include CacheableJson

  has_many :users, inverse_of: :permission

  scope :api_write,  ->{ where( name: 'api-write').first }
  scope :reviewer,   ->{ where( name: 'Reviewer').first }
  scope :supervisor, ->{ where( name: 'Supervisor').first }
  scope :visible,    ->{ where( "name <> 'api-write'") }
end
