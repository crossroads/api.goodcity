module Api
  module V1
    class AuthenticationController < Api::V1::ApiController
      skip_before_action :validate_token, only: [:signup, :verify, :send_pin,
                                                 :current_user_rooms, :signup_and_send_pin]
      skip_authorization_check only: [:signup, :verify, :send_pin, :current_user_rooms, :hasura, :signup_and_send_pin]

      before_action :validate_mobile, only: [:send_pin, :signup_and_send_pin]

      resource_description do
        short "Handle user login and registration"
        description <<-EOS
        ==The login process (in brief):
        * User sends mobile number to <code>/auth/send_pin</code>
        * If the user exists, the server sends a 4-digit pin (<code>OTP code</code>) via SMS to the mobile number
        * Server responds with <code>otp_auth_key</code>
        * User calls <code>/auth/verify</code> with <code>OTP code</code> AND <code>otp_auth_key</code>
        * Server successfully authenticates and returns <code>jwt_token</code>
        * <code>jwt_token</code> is sent with all API requests requiring authorization
        ==Diagrams
        A fuller explanation of the user login / registration process is detailed in the following flowchart diagrams.
        * {Login flowchart}[link:/doc/login_flowchart.svg]
        * {Registration flowchart}[link:/doc/registration_flowchart.svg]
        * {Device registration}[link:/doc/azure_notification_hub.png]
        ==JWT Token
        When sending the JWT token to authenticate each request, place it in
        the request header using the "Authorization Bearer" scheme. Example:
        <code>Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE0MTc1NzkwMTQsImlzcyI6Ikdvb2RDaXR5VGVzdCIsImV4cCI6MTQxNzU4MDgxNH0.x-N_aUb3S5wcNy5i2w2WUZjEA2ud_81u8yQV0JfsT6A</code>
        EOS
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

      api :POST, "/v1/auth/send_pin", "Send SMS code to the registered mobile"
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
      # Lookup user based on mobile. Validate mobile format first.
      def send_pin
        @user ||= User.find_by_mobile(@mobile.mobile)
        @otp_auth_key = otp_auth_key_for(@user, refresh: true)

        if @user && @user.allowed_login?(app_name)
          @user.send_verification_pin(app_name, params[:mobile])
        elsif @user
          return render json: {error: "You are not authorized."}, status: 401
        end
        render json: { otp_auth_key: @otp_auth_key }
      end

      api :POST, "/v1/auth/signup_and_send_pin", "Register a new user"
      def signup_and_send_pin
        @user = find_or_add_user
        send_pin
      end

      api :POST, "/v1/auth/signup", "Register a new user"
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
        @user = User.creation_with_auth(auth_params, app_name)
        if @user.valid? && @user.persisted?
          render json: {otp_auth_key: otp_auth_key_for(@user)}, status: :ok
        else
          render_error(@user.errors.full_messages.join(". "))
        end
      end

      api :POST, "/v1/auth/verify", "Verify OTP code"
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
        @user = AuthenticationService.authenticate(params, strategy: :pin)
        if authenticated_user
          render json: {jwt_token: generate_token(user_id: @user.id), user: Api::V1::UserProfileSerializer.new(@user)}
        else
          render_error({pin: I18n.t("auth.invalid_pin")})
        end
      end

      api :GET, "/v1/auth/current_user_profile", "Retrieve current authenticated user profile details"
      error 401, "Unauthorized"
      error 500, "Internal Server Error"

      def current_user_profile
        authorize!(:current_user_profile, User)

        # If the preferred_langugage is not set for the user, then
        # Set the current_user.preferred_langugage to the locale which is used by the user in browser
        # Or if the user changes his preferred language in the UI, this will update it to
        # the selected language
        # NOTE: This is done in this request because
        #  For setting the preferred_langugage in other endpoints of authentication_controller,
        #  the user needs to be logged out
        current_user.update(preferred_language: I18n.locale)

        # include printers, only if its not donor or browse app
        render json: current_user,
               serializer: Api::V1::UserProfileSerializer,
               include_printers: !(donor_app? || is_browse_app?)
      end

      api :POST, "/v1/auth/register_device", "Register a mobile device to receive notifications"
      param :handle, String, desc: "The registration id for the push messaging service for the platform i.e. fcm/gcm registration id for android"
      param :platform, String, desc: "The azure notification platform name, this should be `fcm/gcm` for android"

      def register_device
        authorize!(:register, :device)
        return render text: platform_error, status: 400 unless valid_platform?
        register_device_for_notifications
        render nothing: true, status: 204
      end

      api :GET, "/v1/auth/current_user_rooms", "Retrieve the list of socketio rooms the user can listen to"
      error 500, "Internal Server Error"

      def current_user_rooms
        # It's ok for current_user to be nil e.g. Anonymous Browse app users
        channels = Channel.channels_for(current_user, app_name)
        render json: channels, root: false
      end

      private

      def validate_mobile
        @mobile = Mobile.new(params[:mobile])

        unless @mobile.valid?
          return render_error(@mobile.errors.full_messages.join(". "))
        end
      end

      def find_or_add_user
        user = User.find_by_mobile(@mobile.mobile)

        if user.blank?
          user = User.creation_with_auth({ mobile: @mobile.mobile }, app_name)
        end
        user
      end

      def render_error(error_message)
        render json: {errors: error_message}, status: 422
      end

      def authenticated_user
        @user.present? && (is_browse_app? || @user.allowed_login?(app_name))
      end

      # Generate a token that contains the otp_auth_key.
      # A client must return this token (which contains the embedded otp_auth_key) AND the correct OTP code
      # to successfully authenticate. This helps prevent man-in-the-middle attacks by ensuring that only this
      # client that can authenticate the OTP code with it.
      # Note: if user is nil, we generate a fake token so as to ward off unruly hackers.
      def otp_auth_key_for(user, refresh: false)
        if user.present?
          AuthenticationService.otp_auth_key_for(user, refresh: refresh)
        else
          AuthenticationService.fake_otp_auth_key
        end
      end

      def auth_params
        attributes = [:mobile, :first_name, :last_name, :email, address_attributes: [:district_id, :address_type]]
        params.require(:user_auth).permit(attributes)
      end

      def valid_platform?
        ["fcm", "aps"].include?(params[:platform])
      end

      def platform_error
        "Unrecognised platform, expecting 'fcm' (Android) or 'aps' (iOS)"
      end

      def register_device_for_notifications
        channels = Channel.channels_for(User.current_user, app_name)
        AzureRegisterJob.perform_later(
          params[:handle],
          channels,
          params[:platform],
          app_name
        )
      end
    end
  end
end
