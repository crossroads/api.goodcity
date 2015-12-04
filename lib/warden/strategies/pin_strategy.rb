require 'warden/strategies/base'

module Warden
  module Strategies
    class PinStrategy < Warden::Strategies::Base

      def valid?
        params["pin"].present? && params['otp_auth_key'].present?
      end

      def authenticate!
        auth_token = AuthToken.find_by_otp_auth_key(params['otp_auth_key'])
        return success!(auth_token.user) if valid_credentials?(auth_token)
        user = auth_token.try(:user)
        has_valid_otp_code?(auth_token) && user ? success!(user) : fail
      end

      private

      def has_valid_otp_code?(auth_token)
        auth_token && auth_token.authenticate_otp(params["pin"], { drift: otp_code_validity })
      end

      def valid_credentials?(auth_token)
        appstore.try(:[], 'number').present? &&
        appstore.try(:[], 'pin').present? &&
        appstore['pin'] == params['pin'] &&
        appstore['number'] == auth_token.try(:user).try(:mobile)
      end

      def otp_code_validity
        Rails.application.secrets.token['otp_code_validity']
      end

      def appstore
        Rails.application.secrets.appstore_reviewer_login
      end

    end
  end
end
