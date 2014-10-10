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
      error 401, "Unauthorized"
      error 403, "Forbidden"
      error 404, "Not Found"
      error 422, "Validation Error"
      error 500, "Internal Server Error"
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
    Send an OTP code via SMS if the given mobile number has an account in our system.
    Always returns 200 regardless of whether mobile number exists or not.
    EOS
    param :mobile, String, desc: "Mobile number with prefixed country code e.g. +85212345678"
    def send_pin
      # Lookup user based on mobile. Don't allow params[:mobile] to be nil
      user = params[:mobile].present? ? User.find_by_mobile(params[:mobile]) : nil
      user.send_verification_pin if user.present?
      render json: { text: "Success! Assuming that mobile number is registered, we've sent a pin code." }
    end

    api :POST, '/v1/auth/signup', "Register a new user"
    description <<-EOS
    Create user and send a new OTP token to the user mobile.
    * If successful, an SMS will be sent with an OTP code
    * Otherwise, return status 403 (Forbidden)

    To understand the registration process in detail refer
    {attached Registration flowcharts}[/doc/registration_flowchart.pdf]
    EOS
    param_group :user_auth
    def signup
      @user = User.creation_with_auth(auth_params)
      if @user.valid? && @user.persisted?
        render json: { message: I18n.t(:success) }, status: :ok
      else
        render json: { errors: @user.errors.full_messages.join }, status: 422
      end
    end

    api :POST, '/v1/auth/verify', "Verify OTP code"
    description <<-EOS
    Verify the OTP code (sent via SMS)
    * If verified, generate and send back an authenticated JWT token and the user id so it can be retreived via an API call
    * If verification fails, return 401 (Unauthorized)

    To understand the registration process in detail refer {attached Login flowchart}[/doc/login_flowchart.pdf]
    EOS
    param :pin, String, desc: "OTP code which is received via sms"
    param :mobile, String, desc: "Mobile number e.g. +85212345678"
    def verify
      user = warden.authenticate!(:pin)
      if warden.authenticated?
        render json: { jwt_token: generate_token(user_id: user.id), user_id: user.id }
      else
        throw(:warden, {status: :unauthorized, message: { text: I18n.t('auth.invalid_credentials'), jwt_token: ""} })
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

    def auth_params
      attributes = [:mobile, :first_name, :last_name, address_attributes: [:district_id, :address_type]]
      params.require(:user_auth).permit(attributes)
    end

    def warden
      request.env['warden']
    end

  end
end
