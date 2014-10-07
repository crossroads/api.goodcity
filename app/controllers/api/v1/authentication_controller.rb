module Api::V1
  class AuthenticationController < Api::V1::ApiController
    skip_before_action :validate_token,
      only: [:is_mobile_exist, :is_unique_mobile_number,:signup, :verify,
      :resend]

    resource_description do
      short 'Handle login, sign up and user verification.'
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

    api :GET, '/v1/auth/resend', "Resend SMS code to the authorized mobile"
    description <<-EOS
    1. If "Bearer" header is empty, locate user using _mobile_  param, or
    2. If "Bearer" header is contains a valid JWT token, locate user using token.

    Bearer header takes the form of:

      AUTHORIZATION "Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE0MDkwMzgzNjUsImlzcyI6Ikdvb2RDaXR5SEsiLCJleHAiOjE0MTAyNDc5NjUsIm1vYmlsZSI6Iis4NTI2MTA5MjAwMSIsIm90cF9zZWNyZXRfa2V5IjoiemRycGZ4c2VnM3cyeWt2aSJ9.lZQaME1oKw7E5cdfks0jG3A_gxlOZ7VfUVG4IMJbc08"
    EOS
    param :mobile, String, desc: "Mobile number with prefixed country code e.g. +85212345678"
    def resend
      (params[:mobile].presence) ? search_by_mobile : search_by_token
    end

    api :POST, '/v1/auth/signup', "Register a new user"
    description <<-EOS
    Create user and send a new OTP token to the user mobile.
    * If successful, generate and return a friendly token which will later be sent back with OTP code.
    * Otherwise, return status 403 (Forbidden)
    EOS
    param_group :user_auth
    def signup
      @result = User.creation_with_auth(auth_params)
      if @result.class == User
        warden.set_user(@result)
        render json: {token: @result.friendly_token,
          message: I18n.t(:success)}, status: :ok
      else
        throw(:warden, {status: :forbidden,
          message: {
          text:  @result,
          token: ""}
      })
      end
    end

    api :POST, '/v1/auth/verify', "Verify OTP code and friendly token"
    description <<-EOS
    Verify both OTP code (sent via SMS) and friendly token are valid
    * If verified, generate and send back a JWT token.
    * If verification fails, return 401 (Unauthorized)
    EOS
    param :token_header, String, desc: "Friendly token"
    param :pin, String, desc: "OTP code which is received via sms"
    def verify
      user = warden.authenticate! :pin
      if warden.authenticated?
        json_token = generate_enc_session_token(user.mobile, token_header) if user
        render json: { user_id: user.try(:id),
          jwt_token: (user.present? ? json_token : "") }, status: :ok
      else
        throw(:warden, {status: :unauthorized,
          message: {
            text: I18n.t('warden.token_invalid'),
            jwt_token: ""}
        })
      end
    end

    api :GET, 'vi/auth/check_mobile', "Is the given mobile number unique?"
    description <<-EOS
    * Return TRUE if mobile number does not exist
    * Return FALSE in all other cases
    EOS
    param :mobile, String, desc: "Mobile number", required: true
    def is_unique_mobile_number
      render json: { is_unique_mobile: unique_user.blank? }, status: :ok
    end

    private

    def unique_user
      User.check_for_mobile_uniqueness(params[:mobile]).first
    end

    def auth_params
      attributes = [:mobile, :first_name, :last_name, address_attributes: [:district_id, :address_type]]
      params.require(:user_auth).permit(attributes)
    end

    def search_by_mobile
      user = unique_user
      if user.present?
        user.send_verification_pin
        render json: { mobile_exist: true ,
          token: user.friendly_token}, status: :ok
      else
        throw(:warden, {status: :unauthorized,
          message: {
            text: I18n.t('auth.mobile_doesnot_exist'),
            token: "",
            mobile_exist: false}
        })
      end
    end

    def search_by_token
      user = User.find_all_by_otp_secret_key(token_header).first
      render json: { token: token_header, message: I18n.t('auth.pin_sent') }, status: :ok if  user.send_verification_pin
    rescue
      throw(:warden, {status: :unauthorized,
        message: {
          text:  I18n.t('auth.mobile_required'),
          token: ""}
      })
    end
  end
end
