Rails.application.config.middleware.use Warden::Manager do |manager|
  manager.default_strategies :pin
  manager.failure_app = ApplicationController.action(:unauthenticated)
end

 # Setup Session Serialization
Warden::Manager.serialize_into_session do |user|
  user.auth_tokens.first.otp_secret_key
end

Warden::Manager.serialize_from_session do |otp_key|
  user.auth_tokens.first.find(otp_key)
end

# Strategies
Warden::Strategies.add(:pin) do
 def valid?
  params["token"] || params["pin"]
 end

 # TODO:: Yet to wrap up completedly with the methods of ActiveModel_otp
 def authenticate!
    unless params["token"].blank?
      user = User.joins(:auth_tokens).where("otp_secret_key = ? ", params["token"]).first
      if user && user.auth_tokens.first.authenticate_otp(params["pin"], {drift: OTP_TOKEN_VALIDITY})
        success! user
      else
        fail! user
      end
    end
 end
end
