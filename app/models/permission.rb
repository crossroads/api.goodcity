class Permission < ActiveRecord::Base
  has_many :users, inverse_of: :permission
end
