module Api::V1
  class AuthenticationController < Api::V1::ApiController
    skip_before_action :validate_token, only: [:signup, :verify, :send_pin]
    skip_authorization_check only: [:signup, :verify, :send_pin]

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

      EOS
      formats ['json']
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

    api :POST, '/v1/auth/send_pin', "Send SMS code to the registered mobile"
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
    error 422, "Invalid mobile number - if mobile prefix doesn't start with +852"
    error 500, "Internal Server Error"
    # Lookup user based on mobile. Validate mobile format first.
    def send_pin
      mobile = params[:mobile]
      if (User::HongKongMobileRegExp === mobile)
        @user = User.find_by_mobile(params[:mobile])
        @user.send_verification_pin if @user.present?
        render json: { otp_auth_key: otp_auth_key_for(@user) }
      else
        attr = I18n.t('activerecord.attributes.user.mobile')
        reason = mobile.blank? ? 'blank' : 'invalid'
        err = I18n.t("activerecord.errors.models.user.attributes.mobile.#{reason}")
        message = I18n.t('errors.format', attribute: attr, message: err)
        render json: { errors: message }, status: 422
      end
    end

    api :POST, '/v1/auth/signup', "Register a new user"
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
      @user = User.creation_with_auth(auth_params)
      if @user.valid? && @user.persisted?
        render json: { otp_auth_key: otp_auth_key_for(@user) }, status: :ok
      else
        render json: { errors: @user.errors.full_messages.join('. ') }, status: 422
      end
    end

    api :POST, '/v1/auth/verify', "Verify OTP code"
    description <<-EOS
    Verify the OTP code (sent via SMS)
    * If verified, generate and send back an authenticated +jwt_token+ and +user+ object
    * If verification fails, return <code>401 (Unauthorized)</code>

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
      @user = warden.authenticate!(:pin)
      if warden.authenticated?
        render json: { jwt_token: generate_token(user_id: @user.id), user: Api::V1::UserProfileSerializer.new(@user) }
      else
        throw(:warden, { status: 401 })
      end
    end

    api :GET, "/v1/auth/current_user_profile", "Retrieve current authenticated user profile details"
    error 401, "Unauthorized"
    error 500, "Internal Server Error"
    def current_user_profile
      authorize!(:current_user_profile, User)
      @user = User.find(User.current_user_id)
      render json: @user, serializer: Api::V1::UserProfileSerializer
    end

    private

    # Generate a token that contains the otp_auth_key.
    # A client must return this token (which contains the embedded otp_auth_key) AND the correct OTP code
    # to successfully authenticate. This helps prevent man-in-the-middle attacks by ensuring that only this
    # client that can authenticate the OTP code with it.
    # Note: if user is nil, we generate a fake token so as to ward off unruly hackers.
    def otp_auth_key_for(user)
      if user.present?
        user.most_recent_token.otp_auth_key
      else
        AuthToken.new.new_otp_auth_key
      end
    end

    def auth_params
      attributes = [:mobile, :first_name, :last_name, address_attributes: [:district_id, :address_type]]
      params.require(:user_auth).permit(attributes)
    end

    def warden
      request.env['warden']
    end

  end
end
