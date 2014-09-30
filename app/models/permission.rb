class Permission < ActiveRecord::Base
  has_many :users, inverse_of: :permission
  scope :reviewer,   ->{ where( name: 'Reviewer').first }
  scope :supervisor, ->{ where( name: 'Supervisor').first }
end
