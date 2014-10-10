require 'warden/strategies/pin_strategy'

Rails.application.config.middleware.use Warden::Manager do |manager|
  manager.default_strategies :pin
  manager.failure_app = UnauthorizedController
end

# Setup Session Serialization
#Warden::Manager.serialize_into_session do |user|
#  user.auth_tokens.first.try(:otp_auth_key)
#end

#Warden::Manager.serialize_from_session do |otp_key|
#  user.auth_tokens.first.find(otp_key)
#end

Warden::Strategies.add(:pin, Warden::Strategies::PinStrategy)
