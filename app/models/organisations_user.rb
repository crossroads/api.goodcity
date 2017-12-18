class OrganisationsUser < ActiveRecord::Base
  belongs_to :organisation
  belongs_to :user

  accepts_nested_attributes_for :user, allow_destroy: true, limit: 1
end
