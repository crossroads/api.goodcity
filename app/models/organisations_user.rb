class OrganisationsUser < ActiveRecord::Base
  belongs_to :organisation
  belongs_to :user
  # position

  validates :organisation_id, :user_id, presence: true
  validates :preferred_contact_number, format: {with: /\A.{8}\Z/}, allow_nil: true
end
