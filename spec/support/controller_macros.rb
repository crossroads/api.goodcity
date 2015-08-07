module ControllerMacros

  def set_locale(change_to_language, default_language='en')
    I18n.locale = default_language
    request.env['HTTP_ACCEPT_LANGUAGE'] = change_to_language
    HttpAcceptLanguage::Middleware.new(lambda {|env| env }).call(request.env)
  end

  # Creates a token and sets the request header effectively logging the user in
  def generate_and_set_token(user=nil)
    user ||= create(:user_with_token)
    current_time = Time.now
    jwt_config = Goodcity.config.jwt
    token = JWT.encode({"iat" => current_time.to_i,
      "iss" => jwt_config.issuer,
      "exp" => (current_time + 14.days).to_i,
      "user_id"  => user.id},
      jwt_config.secret_key,
      jwt_config.hmac_sha_algo)
    request.headers['Authorization'] = "Bearer #{token}"
  end

end
