class ApplicationController < ActionController::API

  include CanCan::ControllerAdditions

  before_action :set_locale
  before_action :validate_token
  helper_method :current_user

  private

  def warden
    request.env['warden']
  end

  def warden_options
    request.env["warden.options"]
  end

  def set_locale
    I18n.locale = http_accept_language.compatible_language_from(I18n.available_locales)
  end

  def current_user
    @current_user ||= begin
      if token_header == 'undefined'
        nil
      else
        otp_secret_key = token['otp_secret_key']
        User.find_all_by_otp_secret_key(otp_secret_key).first
      end
    end
  end

  def token_header
    authorization_token = request.headers['Authorization'].try(:sub, "Bearer","")
    authorization_token.present? ? authorization_token.try(:split, ' ').try(:last) : "undefined"
  end

  def token
    decode_session_token(token_header)
  end

  def validate_token
    unless token_header.blank? || token_header == "undefined"
      validate_authenticity_of_token(token)
    else
      throw(:warden, {status: :unauthorized,
       message: I18n.t('warden.token_invalid'), value: false})
    end
  end

  # Generate an encoded Json Web Token to send to client app
  # on successful completion of the authentication process
  def generate_enc_session_token(user_mobile, user_otp_skey)
    cur_time = Time.now
    JWT.encode({"iat" => cur_time.to_i,
      "iss" => jwt_config['issuer'],
      "exp" => (cur_time + 14.days).to_i,
      "mobile"  => user_mobile,
      "otp_secret_key"  => user_otp_skey},
      jwt_config['secret_key'],
      jwt_config['hmac_sha_algo'])
  end

  # Decode the json web token when we receive it from the client
  # before proceeding ahead
  def decode_session_token(token)
    begin
      JWT.decode(token, jwt_config['secret_key'], jwt_config['hmac_sha_algo'])
    rescue JWT::DecodeError
      throw(:warden, {status: :unauthorized, message: I18n.t('warden.token_invalid'), value: false})
    end
  end

  # Is the JWT token is authentic? If authentic then allow to login
  # exp should be in the future
  # iat should be in the past
  # Time.now should not be more than 14 days, that means time.now and
  # exp should not be equal
  def validate_authenticity_of_token(jwt_decoded_json)
    unless (jwt_decoded_json.all? &:blank?)
      cur_time = Time.now
      iat_time = Time.at(jwt_decoded_json["iat"])
      exp_time = Time.at(jwt_decoded_json["exp"])
      case cur_time.present?
        when (iat_time < cur_time && exp_time >= cur_time && iat_time < exp_time) == true
          {message: I18n.t('warden.token_valid'), status: :ok , value: true}
        when iat_time > cur_time == true
          throw(:warden, {status: :forbidden,
            message: I18n.t('warden.token_invalid'), value: false})
        when exp_time < cur_time == true
          throw(:warden, {status: :forbidden,
            message: I18n.t('warden.token_expired'), value: false})
        when iat_time < exp_time == true
          throw(:warden, {status: :forbidden,
            message: I18n.t('warden.token_invalid'), value: false})
        else
          throw(:warden, {status: :unauthorized,
            message: I18n.t('warden.token_invalid'), value: false})
      end
    else
      throw(:warden, {status: :unauthorized,
        message: I18n.t('warden.token_invalid'), value: false})
    end
  end

  def jwt_config
    Rails.application.secrets.jwt
  end

end
