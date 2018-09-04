class OrganisationsUser < ActiveRecord::Base
  belongs_to :organisation
  belongs_to :user
  # position

  validates :organisation_id, :user_id, presence: true

end

