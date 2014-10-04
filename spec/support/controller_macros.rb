module ControllerMacros

  def set_locale(change_to_language, default_language='en')
    I18n.locale = default_language
    request.env['HTTP_ACCEPT_LANGUAGE'] = change_to_language
    HttpAcceptLanguage::Middleware.new(lambda {|env| env }).call(request.env)
  end

  # Creates a token and sets the request header effectively logging the user in
  def generate_and_set_token(user=nil)
    user ||= create(:user_with_token)
    cur_time = Time.now
    jwt_config = Rails.application.secrets.jwt
    mobile = user.mobile
    otp_secret_key = user.friendly_token
    token = JWT.encode({"iat" => cur_time.to_i,
      "iss" => jwt_config['issuer'],
      "exp" => (cur_time + 14.days).to_i,
      "mobile"  => mobile,
      "otp_secret_key"  => otp_secret_key},
      jwt_config['secret_key'],
      jwt_config['hmac_sha_algo'])
    request.headers['Authorization'] = "Bearer #{token}"
  end

end
