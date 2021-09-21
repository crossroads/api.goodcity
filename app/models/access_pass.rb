class AccessPass < ApplicationRecord
  before_create :set_access_key

  belongs_to :generated_by, class_name: 'User'
  belongs_to :printer
  has_many :access_pass_roles, dependent: :destroy
  has_many :roles, through: :access_pass_roles

  def refresh_pass
    update(
      access_key: generate_token,
      generated_at: Time.current
    )
  end

  def valid_pass?
    Time.current < (generated_at + 30.seconds)
  end

  def self.find_valid_pass(key)
    pass = find_by(access_key: key)
    pass.try(:valid_pass?) && pass
  end

  private

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
