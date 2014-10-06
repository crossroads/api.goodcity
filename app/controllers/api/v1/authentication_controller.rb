module Api::V1
  class AuthenticationController < Api::V1::ApiController
    skip_before_action :validate_token,
      only: [:is_mobile_exist, :is_unique_mobile_number,:signup, :verify,
      :resend]

    resource_description do
      short 'Resend, signup, verify and is_unique_mobile_number.'
      formats ['json']
      error 401, "Unauthorized"
      error 403, "Forbidden"
      error 404, "Not Found"
      error 422, "Validation Error"
      error 500, "Internal Server Error"
    end

    def_param_group :user do
      param :auth_params, Hash, required: true do
        param :mobile, String, allow_nil: false, desc: "What is user Mobile number"
        param :first_name, String, allow_nil: false, desc: "What is user's given name?"
        param :last_name, String, allow_nil: false, desc: "What is user's family name?"
        param :address_attributes, Hash, required: true do
          param :district_id, Fixnum, allow_nil: false, desc: "What belongs to which district?"
          param :address_type, String, allow_nil: false, desc: "Helps to decide address type e.g. profile or collection etc "
        end
      end
    end

    api :GET, '/v1/auth/resend', "Resend SMS code to the autherized mobile"
    description "If token_header is undefined/empty in that case search user by
    mobile number. However if token_header is present and not undefined in that
    case search by the JWT token"
    params :token_header, String, desc: "User token/mobile number"
    def resend
      (token_header != "undefined" && token_header.present?) ? search_by_token : search_by_mobile
    end

    api :POST, '/v1/auth/signup', "Register user"
    description "Register user, during save process generate unique otp token.
    Call twilio api internally to validate the Mobile number.
    On successful validation
      generate otp code and send sms to user.
      return api json response as friendly token
    On failure
      return forbidden error with error message"
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

    api :POST, '/v1/auth/verify', "Verify token and sms code"
    description "First of all verify passed sms code and step one token is validate
    (to check that call warden pin strategy)?
    if it returns user object and authenticated? as true then generate JWT token
     response back with :OK and json_token as JWT token
    if it fails to verify the token and sms code
      response back with unauthorized error and json_token will be empty
    "
    params :token_header, String, desc: "user's step one friendly token"
    params :pin, String, desc: "user's otp code which is received via sms"
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
    api :GET, 'vi/auth/check_mobile', "To find out whether mobile number is unique or not?"
    description "response will be TRUE if mobile number does not exist otherwise it will
    return FALSE"
    params :mobile, String, desc: "mobile number"
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
      # :mobile, :first_name, :last_name,
      #   address_attributes: [:district_id, :address_type])
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
