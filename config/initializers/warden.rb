Rails.application.config.middleware.use Warden::Manager do |manager|
  manager.default_strategies :pin
  manager.failure_app = UnauthorizedController
end

# Setup Session Serialization
Warden::Manager.serialize_into_session do |user|
  user.auth_tokens.first.try(:otp_secret_key)
end

Warden::Manager.serialize_from_session do |otp_key|
  user.auth_tokens.first.find(otp_key)
end

# Pin Strategy
Warden::Strategies.add(:pin) do

  def valid?
    otp_secret_key.present? && params["pin"].present?
  end

  def authenticate!
    user = User.find_all_by_otp_secret_key(otp_secret_key).first
    if user && user.most_recent_token.authenticate_otp(params["pin"], {drift: otp_code_validity})
      success! user
    else
      fail! user
    end
  end

  def otp_code_validity
    Rails.application.secrets.token['otp_code_validity']
  end

  def otp_secret_key
    env['HTTP_AUTHORIZATION'].try(:split, ' ').try(:last)
  end

end
