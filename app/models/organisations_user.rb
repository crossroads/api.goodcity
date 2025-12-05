# frozen_string_literal: true

class OrganisationsUser < ApplicationRecord
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

  before_save :validate_status
  before_validation :downcase_status

  scope :active, -> { where(status: ACTIVE_STATUS) }

  def self.all_status
    ALL_STATUS
  end

  def downcase_status
    self.status = status.downcase
  end

  def validate_status
    raise I18n.t('organisations_user_builder.invalid.status') unless ALL_STATUS.include?(status)
  end
end
