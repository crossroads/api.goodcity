require 'warden/strategies/pin_strategy'
require 'warden/strategies/pin_jwt_strategy'

Rails.application.config.middleware.use Warden::Manager do |manager|
  manager.intercept_401 = false
  manager.default_strategies :pin
  manager.failure_app = UnauthorizedController
end

Warden::Strategies.add(:pin, Warden::Strategies::PinStrategy)
Warden::Strategies.add(:pin_jwt, Warden::Strategies::PinJwtStrategy)
