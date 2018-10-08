class Beneficiary < ActiveRecord::Base
  belongs_to :identity_type
  belongs_to :created_by, class_name: 'User'
end
