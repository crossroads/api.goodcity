require 'warden/strategies/pin_strategy'

Rails.application.config.middleware.use Warden::Manager do |manager|
  manager.default_strategies :pin
  manager.failure_app = UnauthorizedController
end

Warden::Strategies.add(:pin, Warden::Strategies::PinStrategy)
