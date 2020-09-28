require 'goodcity/authentication/strategies/pin_strategy'
require 'goodcity/authentication/strategies/pin_jwt_strategy'

AuthenticationService::Strategies.add(:pin,     Goodcity::Authentication::Strategies::PinStrategy)
AuthenticationService::Strategies.add(:pin_jwt, Goodcity::Authentication::Strategies::PinJwtStrategy)

AuthenticationService::Strategies.default_strategy(:pin)