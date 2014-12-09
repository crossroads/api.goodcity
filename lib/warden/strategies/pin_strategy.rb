require 'warden/strategies/base'

module Warden
  module Strategies
    class PinStrategy < Warden::Strategies::Base

      def valid?
        params["pin"].present? && params['otp_auth_key'].present?
      end

      def authenticate!
        auth_token = AuthToken.find_by_otp_auth_key(params['otp_auth_key'])
        if auth_token && auth_token.authenticate_otp(params["pin"], { drift: otp_code_validity })
          if (user = auth_token.user)
            success!(user)
          else
            fail
          end
        else
          fail
        end
      end

      private

      def otp_code_validity
        Rails.application.secrets.token['otp_code_validity']
      end

    end
  end
end
