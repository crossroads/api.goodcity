module Api
  module V2
    class AuthenticationController < Api::V2::ApiController
      skip_before_action :validate_token, only: [:signup, :verify, :send_pin]
      skip_authorization_check only: [:signup, :verify, :send_pin, :hasura, :goodchat, :resend_pin]

      resource_description do
        short "The login process"
        formats ["json"]
      end

      def_param_group :user_auth do
        param :user_auth, Hash, required: true do
          param :mobile, String, desc: "Mobile number e.g. +85212345678"
          param :first_name, String, allow_nil: false, desc: "Given name (first name)"
          param :last_name, String, allow_nil: false, desc: "Family name (last name)"
          param :address_attributes, Hash, required: true do
            param :district_id, String, allow_nil: false, desc: "Hong Kong district"
            param :address_type, String, allow_nil: false, desc: "Type of address e.g. 'Profile' or 'Collection'"
          end
        end
      end

      api :POST, "/v2/auth/send_pin", "Send SMS code to the registered mobile"
      description <<-EOS
        Send an OTP code via SMS if the given mobile number has an account in the system.

        Each time a new OTP code is generated, the +otp_auth_key+ is cycled. The client is
        responsible for sending back the newest +otp_auth_key+ with the OTP code.
        If the user account doesn't exist, a random +otp_auth_key+ is returned.

        ===Response status codes
        * 200 - returned regardless of whether mobile number exists or not
        * 422 - returned if the mobile number is invalid
      EOS
      param :mobile, String, desc: "Mobile number with prefixed country code e.g. +85262345678"
      error 401, "Unauthorized"
      error 422, "Invalid mobile number - if mobile prefix doesn't start with +852"
      error 500, "Internal Server Error"
      def send_pin
        mobile = Mobile.new(params[:mobile])

        raise Goodcity::ValidationError.new(mobile.errors.full_messages) unless mobile.valid?

        user = User.find_by_mobile(mobile.mobile)

        otp_auth_key = if user.blank?
          AuthenticationService.fake_otp_auth_key
        else
          AuthenticationService.send_pin(user, app_name)
          AuthenticationService.otp_auth_key_for(user)
        end

        render json: { otp_auth_key: wrap_otp_in_jwt(otp_auth_key, pin_method: :mobile, mobile: params[:mobile]) }
      end

      def resend_pin
        mobile = Mobile.new(params[:mobile])
        raise Goodcity::ValidationError.new(mobile.errors.full_messages) unless mobile.valid?

        current_user.send_verification_pin(app_name, params[:mobile])
        otp_auth_key = AuthenticationService.otp_auth_key_for(current_user)
        render json: { otp_auth_key: wrap_otp_in_jwt(otp_auth_key, pin_method: :mobile, mobile: params[:mobile]) }
      end

      api :POST, "/v2/auth/signup", "Register a new user"
      description <<-EOS
        Create a new user and send an OTP token to the user's mobile.

        If the mobile number already exists, do not create a new user. Send an OTP
        code to the existing user's mobile and disregard any other signup params.

        ===If successful:
        * an OTP code will be sent via SMS to the user's mobile
        * an +otp_auth_key+ will be returned to the client

        ===Hong Kong mobile numbers
        * must begin with +8525, +8526, or +8529
        * must contain a further 7 digits.

        ====Valid examples:
        * +85251234567
        * +85261234567
        * +85291234567

        ====Invalid examples:

        * +11112345678  - must begin with +8525, +8526, or +8529
        * +85212345678  - must begin with +8525, +8526, or +8529
        * +8525234567   - too short
        * +852523456789 - too long

        To understand the registration process in detail please refer to the
        {attached Registration flowcharts}[/doc/registration_flowchart.svg]
      EOS
      param_group :user_auth
      error 422, "Validation Error"
      error 500, "Internal Server Error"
      def signup
        mobile  = auth_params[:mobile].presence
        email   = auth_params[:email].presence
        status  = 200

        user = User.find_user_by_mobile_or_email(mobile, email)
        user ||= begin
          status = 201
          AuthenticationService.register_user(auth_params)
        end

        AuthenticationService.send_pin(user, app_name)

        otp_auth_key  = AuthenticationService.otp_auth_key_for(user)
        token         = wrap_otp_in_jwt(otp_auth_key, pin_method: mobile ? :mobile : :email)

        render json: { otp_auth_key: token }, status: status
      end

      api :POST, "/v2/auth/verify", "Verify OTP code"
      description <<-EOS
        Verify the OTP code (sent via SMS)
        * If verified, generate and send back an authenticated +jwt_token+ and +user+ object
        * If verification fails, return <code>422 (Unprocessable Entity)</code>

        ===If successful
        * a +jwt_token+ will be returned. This should be included in all subsequent requests as part of the AUTHORIZATION header to authenticate the API calls.
        * the +user+ object is returned.

        To understand the registration process in detail refer {attached Login flowchart}[/doc/login_flowchart.pdf]
      EOS
      param :pin, String, desc: "OTP code received via SMS"
      param :otp_auth_key, String, desc: "The authentication key received during 'send_pin' or 'signup' steps"
      error 401, "Unauthorized"
      error 403, "Forbidden"
      error 422, "Validation Error"
      error 500, "Internal Server Error"
      def verify
        user      = AuthenticationService.authenticate!(params, strategy: :pin_jwt)
        jwt_token = AuthenticationService.generate_token(user, api_version: API_VERSION)

        render json: { jwt_token: jwt_token, **Api::V2::UserSerializer.new(user, serializer_options(:user)) }
      end

      api :POST, "/v2/auth/hasura", "Authentication for the Hasura GraphQL server"
      description <<-EOS
        Generates an alternative JWT which can be used to authenticate to the Hasura GraphQL server
        * If authenticated, generate and send back an authenticated +jwt_token+ for hasura
        * If unauthenticated fails, return <code>403 (Forbidden)</code>
      EOS
      def hasura
        token = HasuraService.authenticate current_user
        render json: { token: token }, status: :ok
      end

      api :POST, "/v2/auth/goodchat", "Webhook authentication for the GoodChat server"
      description <<-EOS
        Returns a GoodChat specific payload including
        * A display name
        * A user id
        * An array of chat permissions
      EOS
      def goodchat
        raise Goodcity::AccessDeniedError if current_user.roles.empty?

        permissions = []
        permissions << "chat:customer" if  (current_user.reviewer? || current_user.supervisor?)
        permissions << "admin" if  (current_user.system_user? || current_user.supervisor?)

        render json: {
          userId: current_user.id,
          displayName: "#{current_user.first_name} #{current_user.last_name}",
          permissions: permissions
        }, status: :ok
      end

      private

      def wrap_otp_in_jwt(otp_auth_key, pin_method: :mobile, mobile: nil)
        Token.new.generate_otp_token(pin_method: pin_method,
                                     otp_auth_key: otp_auth_key,
                                     mobile: mobile)
      end

      def auth_params
        attributes = [:mobile, :first_name, :last_name, :email, address_attributes: [:district_id, :address_type]]
        params.require(:user_auth).permit(attributes)
      end
    end
  end
end
