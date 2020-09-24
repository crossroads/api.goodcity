require 'warden/strategies/base'

module Warden
  module Strategies
    class PinStrategy < Warden::Strategies::Base
      def valid?
        request_params[:pin].present? && request_params[:otp_auth_key].present?
      end

      def lookup_auth_token
        AuthToken.find_by_otp_auth_key(request_params[:otp_auth_key])
      end

      def pin_method
        request_params[:pin_for]&.to_sym || :mobile
      end

      def authenticate!
        auth_token = lookup_auth_token
        return success!(auth_token.user) if valid_app_store_credentials?(auth_token)

        user = auth_token.try(:user)
        return fail unless valid_otp_code?(auth_token) && valid_user(user)
        user.set_verified_flag(pin_method) if pin_method.present?
        success!(user)
      end

      private

      def request_params
        @request_params ||= env['action_dispatch.request.parameters'].with_indifferent_access
      end

      def valid_user(user)
        user.present? && !user.disabled
      end

      def valid_otp_code?(auth_token)
        auth_token&.authenticate_otp(request_params['pin'], drift: otp_code_validity)
      end

      def valid_app_store_credentials?(auth_token)
        appstore.try(:[], 'number').present? &&
          appstore.try(:[], 'pin').present? &&
          appstore['pin'] == request_params['pin'] &&
          appstore['number'] == auth_token.try(:user).try(:mobile)
      end

      def otp_code_validity
        Rails.application.secrets.token[:otp_code_validity]
      end

      def appstore
        Rails.application.secrets.appstore_reviewer_login
      end
    end
  end
end
