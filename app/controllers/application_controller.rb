class ApplicationController < ActionController::API

  include CanCan::ControllerAdditions

  before_action :validate_token
  before_action :set_locale
  helper_method :current_user

  def warden
    env["warden"]
  end

  def warden_options
    env["warden.options"]
  end

  private

  def set_locale
    I18n.locale = http_accept_language.compatible_language_from(I18n.available_locales)
  end

  def current_user
    warden.user
  end

  def token_header
    request.headers['Authorization'].try(:split, ' ').try(:last)
  end

  def validate_token
    unless token_header.blank?
      jwt_decoded_json = decode_session_token(token_header)
      auth_info = validate_authenticity_of_jwt(jwt_decoded_json)
    end
  end

  # Generate an encoded Json Web Token to send to client app
  # on successful completion of the authentication process
  def generate_enc_session_token(user_mobile, user_otp_skey)
    cur_time = Time.now
    JWT.encode({"iat" => cur_time.to_i,
      "iss" => ISSUER,
      "exp" => (cur_time + 14.days).to_i,
      "mobile"  => user_mobile,
      "otp_secret_key"  => user_otp_skey},
      SECRET_KEY,
      HMAC_SHA_ALGO)
  end

  # Decode the json web token when we receive it from the client
  # before proceeding ahead
  def decode_session_token(token)
    #TODO: while decoding time use Time.at(iat)
    begin
      JWT.decode(token, SECRET_KEY, HMAC_SHA_ALGO)
    rescue JWT::DecodeError
      render nothing: true, status: :unauthorized
    end
  end

  # Is the JWT token is authentic? If authentic then allow to login
  # exp should be in the future
  # iat should be in the past
  # Time.now should not be more than 14 days, that means time.now and
  # exp should not be equal
  def validate_authenticity_of_jwt(jwt_decoded_json)
    unless jwt_decoded_json.all? &:blank?
      cur_time = Time.now
      iat_time = Time.at(jwt_decoded_json["iat"])
      exp_time = Time.at(jwt_decoded_json["exp"])
      case cur_time.present?
        when (iat_time < cur_time && exp_time >= cur_time && iat_time < exp_time) == true
          {msg: I18n.t('warden.token_valid'), status: :ok , value: true}
        when iat_time > cur_time == true
          throw(:warden, {status: :forbidden,
            msg: I18n.t('warden.token_invalid'), value: false})
        when exp_time < cur_time == true
          throw(:warden, {status: :forbidden,
            msg: I18n.t('warden.token_expired'), value: false})
        when iat_time < exp_time == true
          throw(:warden, {status: :forbidden,
            msg: I18n.t('warden.token_invalid'), value: false})
        else
          throw(:warden, {status: :unauthorized,
            msg: I18n.t('warden.token_invalid'), value: false})
      end
    else
      throw(:warden, {status: :unauthorized,
        msg: I18n.t('warden.token_invalid'), value: false})
    end
  end
end
