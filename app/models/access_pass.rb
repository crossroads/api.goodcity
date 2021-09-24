class AccessPass < ApplicationRecord
  before_create :set_access_key

  belongs_to :generated_by, class_name: 'User'
  belongs_to :printer
  has_many :access_passes_roles, dependent: :destroy
  has_many :roles, through: :access_passes_roles

  validates :access_expires_at, presence: true
  validate :access_expires_within_week

  def refresh_pass
    update(
      access_key: generate_token,
      generated_at: Time.current
    )
  end

  def valid_pass?
    Time.current < (generated_at + ACCESS_PASS_VALIDITY_TIME)
  end

  def self.find_valid_pass(key)
    pass = find_by(access_key: key)
    pass.try(:valid_pass?) && pass
  end

  private

  def access_expires_within_week
    return if access_expires_at.blank?

    if 1.week.from_now < access_expires_at
      errors.add(:end_date, "must be less than a week time.")
    end
  end

  def set_access_key
    self.access_key = generate_token
    self.generated_at = Time.current
  end

  def generate_token
    loop do
      token = (SecureRandom.random_number(9e5) + 1e5).to_i
      break token unless AccessPass.where(access_key: token).exists?
    end
  end
end
