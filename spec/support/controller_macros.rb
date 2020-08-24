module ControllerMacros
  def set_locale(change_to_language, default_language='en')
    I18n.locale = default_language
    request.env['HTTP_ACCEPT_LANGUAGE'] = change_to_language
    HttpAcceptLanguage::Middleware.new(lambda {|env| env }).call(request.env)
  end

  # Creates a token and sets the request header effectively logging the user in

  def generate_and_set_token(user = nil)
    user ||= create(:user, :with_token)
    User.current_user = user
    jwt_config = Rails.application.secrets.jwt
    payload = create_payload(jwt_config)
    token = JWT.encode(payload, jwt_config[:secret_key], jwt_config[:hmac_sha_algo])
    request.headers['Authorization'] = "Bearer #{token}"
  end

  def create_payload(jwt_config)
    {
      iss: jwt_config[:issuer],
      exp: 14.days.from_now.to_i,
      user_id: User.current_user.id
    }
  end
end
