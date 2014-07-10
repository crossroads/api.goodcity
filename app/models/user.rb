class User < ActiveRecord::Base
  has_many :auth_tokens
  has_many :offers, foreign_key: :created_by_id, inverse_of: :created_by
  has_many :messages, foreign_key: :sender_id, inverse_of: :sender
  has_and_belongs_to_many :permissions
  accepts_nested_attributes_for :auth_tokens

  def reviewer?
    permissions.pluck(:name).include?('Reviewer')
  end

  def supervisor?
    permissions.pluck(:name).include?('Supervisor')
  end

  def admin?
    administrator?
  end

  def administrator?
    permissions.pluck(:name).include?('Administrator')
  end

  def authenticate(mobile)
    send_verification_pin if mobile.eql?(self.mobile)
  end

  def generate_verification_pin

  end

  def send_verification_pin
    return TwilioServices.new(self)
  end

end
