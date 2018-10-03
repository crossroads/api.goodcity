class Beneficiary < ActiveRecord::Base
  belongs_to :identity_type
  belongs_to :created_by, class_name: 'User'

  scope :my_beneficiaries, -> { where("created_by_id = (?)", User.current_user.try(:id)) }
end
