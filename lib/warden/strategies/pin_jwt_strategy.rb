require 'warden/strategies/base'

module Warden
  module Strategies
    class PinJwtStrategy < PinStrategy
      def valid?
        request_params["pin"].present? && jwt_token.valid? && jwt_token.otp?
      end

      def pin_method
        jwt_token.read('pin_method')
      end

      def lookup_auth_token
        auth_key = jwt_token.read('otp_auth_key');
        AuthToken.find_by_otp_auth_key(auth_key)
      end

      private

      def jwt_token
        @jwt_data ||= Token.new(bearer: request_params['otp_auth_key'])
      end
    end
  end
end
