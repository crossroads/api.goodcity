# frozen_string_literal: true

class OrganisationsUser < ActiveRecord::Base
  module Status
    PENDING   = 'pending'
    APPROVED  = 'approved'
    EXPIRED   = 'expired'
    DENIED    = 'denied'
  end

  ACTIVE_STATUS   = [Status::PENDING, Status::APPROVED].freeze
  INITIAL_STATUS  = Status::PENDING
  ALL_STATUS      = [Status::PENDING, Status::APPROVED, Status::EXPIRED, Status::DENIED].freeze

  belongs_to :organisation
  belongs_to :user

  validates :organisation_id, :user_id, presence: true
  validates :preferred_contact_number, format: {with: /\A.{8}\Z/}, allow_nil: true

  scope :active, -> { where(status: ACTIVE_STATUS) }

  def self.all_status
    ALL_STATUS
  end
end
