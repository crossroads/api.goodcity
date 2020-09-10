class OrganisationsUser < ApplicationRecord
  module Status
    PENDING   = 'pending'.freeze
    APPROVED  = 'approved'.freeze
    EXPIRED   = 'expired'.freeze
    DENIED    = 'denied'.freeze
  end

  ACTIVE_STATUS   = [Status::PENDING, Status::APPROVED].freeze
  INITIAL_STATUS  = Status::PENDING

  belongs_to :organisation
  belongs_to :user

  validates :organisation_id, :user_id, presence: true
  validates :preferred_contact_number, format: {with: /\A.{8}\Z/}, allow_nil: true

  scope :active, ->{ where(status: ACTIVE_STATUS) }
end
