require 'warden/strategies/base'

module Warden
  module Strategies
    class PinStrategy < Warden::Strategies::Base

      def valid?
        params["pin"].present? && params['otp_auth_key'].present?
      end

      def authenticate!
        auth_token = AuthToken.find_by_otp_auth_key(params['otp_auth_key'])

        if appstore.try(:[], 'number').present? && appstore.try(:[], 'pin').present? &&
          appstore['pin'] == params['pin'] && appstore['number'] == auth_token.try(:user).try(:mobile)
          return success!(auth_token.user)
        end

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
        Goodcity.config.token.otp_code_validity
      end

      def appstore
        Goodcity.config.appstore_reviewer_login
      end

    end
  end
end
