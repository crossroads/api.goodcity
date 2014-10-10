class User < ActiveRecord::Base
  has_one :address, as: :addressable, dependent: :destroy
  has_many :auth_tokens, dependent: :destroy
  has_many :offers, foreign_key: :created_by_id, inverse_of: :created_by
  has_many :reviewed_offers, foreign_key: :reviewed_by_id, inverse_of: :reviewed_by, class_name: 'Offer'
  has_many :messages, foreign_key: :recipient_id, inverse_of: :recipient
  has_many :sent_messages, class_name: 'Message', foreign_key: :sender_id, inverse_of: :sender

  has_many :subscriptions, dependent: :destroy
  has_many :offers_subscription, class_name: "Offer", through: :subscriptions

  belongs_to :permission, inverse_of: :users

  accepts_nested_attributes_for :address, allow_destroy: true

  validates :mobile, presence: true, uniqueness: true

  after_create :generate_auth_token

  scope :check_for_mobile_uniqueness, -> (entered_mobile) { where("mobile = ?", entered_mobile) }

  scope :reviewers,   -> { where( permissions: { name: 'Reviewer'   } ).joins(:permission) }
  scope :supervisors, -> { where( permissions: { name: 'Supervisor' } ).joins(:permission) }

  def self.creation_with_auth(user_params)
    user = new(user_params)
    begin
      transaction do
        user.save!
        user.send_verification_pin
      end
    rescue Twilio::REST::RequestError => e
      msg = e.message.try(:split,'.').try(:first)
      user.errors.add(:base, msg)
    rescue Exception => e
      user.errors.add(:base, e.message)
    end
    user
  end

  def most_recent_token
    auth_tokens.most_recent.first
  end

  def full_name
    [first_name, last_name].reject(&:blank?).map(&:downcase).map(&:capitalize).join(' ')
  end

  def reviewer?
    permission.try(:name) == 'Reviewer'
  end

  def supervisor?
    permission.try(:name) == 'Supervisor'
  end

  def admin?
    administrator?
  end

  def administrator?
    permission.try(:name) == 'Administrator'
  end

  def send_verification_pin
    EmailFlowdockService.new(self).send_otp
    TwilioService.new(self).sms_verification_pin
  end

  private

  def generate_auth_token
    auth_tokens.create({user_id:  self.id})
  end

end
