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

# Strategies
Warden::Strategies.add(:pin) do
  def valid?
    auth_token.present? && params["pin"].present?
  end
  def authenticate!
    user = User.find_by_otp_secret_key(auth_token).first
    otp_token_validity = Rails.application.secrets.jwt['otp_token_validity']
    if user && user.auth_tokens.recent_auth_token.authenticate_otp(params["pin"], {drift: otp_token_validity})
      success! user
    else
      fail! user
    end
 end

 def auth_token
    env['HTTP_AUTHORIZATION'].try(:split, ' ').try(:last)
 end
end
