class AccessPassRole < ApplicationRecord
  belongs_to :access_pass
  belongs_to :role
end
