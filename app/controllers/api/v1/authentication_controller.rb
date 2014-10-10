module Api::V1
  class AuthenticationController < Api::V1::ApiController
    skip_before_action :validate_token, only: [:signup, :verify, :send_pin, :is_unique_mobile_number]

    resource_description do
      short "Handle user login and registration"
      description <<-EOS
      ==Diagrams
      * {Login flowchart}[link:/doc/login_flowchart.pdf]
      * {Registration flowchart}[link:/doc/registration_flowchart.pdf]
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

    Response status codes
    * 200 - returned regardless of whether mobile number exists or not
    * 422 - returned if the mobile does not start with "+852"

    Each time a new OTP code is generated, the +otp_auth_key+ is cycled. The client is
    responsible for sending back the newest +otp_auth_key+ with the OTP code.
    If the user account doesn't exist, a random +otp_auth_key+ is returned.
    EOS
    param :mobile, String, desc: "Mobile number with prefixed country code e.g. +85212345678"
    error 422, "Invalid mobile number - if mobile prefix doesn't start with +852"
    error 500, "Internal Server Error"
    def send_pin
      # Lookup user based on mobile. Don't allow params[:mobile] to be nil
      mobile = params[:mobile]
      if mobile.starts_with?("+852")
        @user = User.find_by_mobile(mobile)
        @user.send_verification_pin if @user.present?
        render json: { otp_auth_key: otp_auth_key_for(@user) }
      else
        render json: { errors: I18n.t('auth.invalid_mobile') }, status: 422
      end
    end

    api :POST, '/v1/auth/signup', "Register a new user"
    description <<-EOS
    Create a new user and send an OTP token to the user's mobile.

    Upon success:
    * an OTP code will be sent via SMS to the user's mobile
    * an +otp_auth_key+ will be returned to the client

    To understand the registration process in detail please refer to the
    {attached Registration flowcharts}[/doc/registration_flowchart.pdf]
    EOS
    param_group :user_auth
    error 422, "Validation Error"
    error 500, "Internal Server Error"
    def signup
      @user = User.creation_with_auth(auth_params)
      if @user.valid? && @user.persisted?
        render json: { otp_auth_key: otp_auth_key_for(@user) }, status: :ok
      else
        render json: { errors: @user.errors.full_messages.join }, status: 422
      end
    end

    api :POST, '/v1/auth/verify', "Verify OTP code"
    description <<-EOS
    Verify the OTP code (sent via SMS)
    * If verified, generate and send back an authenticated +jwt_token+ and +user_id+
    * If verification fails, return 401 (Unauthorized)

    To understand the registration process in detail refer {attached Login flowchart}[/doc/login_flowchart.pdf]
    EOS
    param :pin, String, desc: "OTP code received via SMS"
    param :otp_auth_key, String, desc: "The authentication key received during 'send_pin' or 'signup' steps"
    error 401, "Unauthorized"
    error 403, "Forbidden"
    error 422, "Validation Error"
    error 500, "Internal Server Error"
    def verify
      user = warden.authenticate!(:pin)
      if warden.authenticated?
        render json: { jwt_token: generate_token(user_id: user.id), user_id: user.id }
      else
        throw(:warden, {status: :unauthorized, jwt_token: ""})
      end
    end

    #api :GET, 'vi/auth/check_mobile', "Is the given mobile number unique?"
    #description <<-EOS
    #* Return TRUE if mobile number does not exist
    #* Return FALSE in all other cases
    #EOS
    #param :mobile, String, desc: "Mobile number", required: true
    def is_unique_mobile_number
      unique_user = User.check_for_mobile_uniqueness(params[:mobile]).first
      render json: { is_unique_mobile: unique_user.blank? }
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
