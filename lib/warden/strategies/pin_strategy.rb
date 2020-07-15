require 'warden/strategies/base'

module Warden
  module Strategies
    class PinStrategy < Warden::Strategies::Base
      def valid?
        params["pin"].present? && params['otp_auth_key'].present?
      end

      def authenticate!
        auth_token = AuthToken.find_by_otp_auth_key(params['otp_auth_key'])
        return success!(auth_token.user) if valid_app_store_credentials?(auth_token)
        user = auth_token.try(:user)
        has_valid_otp_code?(auth_token) && valid_user(user) ? success!(user) : fail
      end

      private

      def valid_login_permissions_for(user)
        # 1. get the permissions of the user
        role_permissions = user.roles.include(:permissions)
        permissions = role_permissions.map { |role| role.permissions.map(&:name) }
        # 2. get the app name
        app_name = request.env['HTTP_X_GOODCITY_APP_NAME'].split('.')[0]
        # 3. check if the user has permission to log into the respective app and return true / false
        case app_name
        when DONOR_APP
          true
        when ADMIN_APP
          permissions.include? 'can_login_to_admin'
        when STOCK_APP
          permissions.include? 'can_login_to_stock'
        when BROWSE_APP
          permissions.include? 'can_login_to_browse'
        end
      end

      def valid_user(user)
        user.present? && !user.disabled
      end

      def has_valid_otp_code?(auth_token)
        auth_token && auth_token.authenticate_otp(params["pin"], drift: otp_code_validity)
      end

      def valid_app_store_credentials?(auth_token)
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
