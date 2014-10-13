#
# A class to handle JWT token encode/decode/verification
#
# Initialize token with request header e.g. Token.new( bearer: request.headers['Authorization'] )
# Call token.valid? and token.errors
# E.g. throw(:warden, { status: :unauthorized, message: token.errors.full_messages.join }) unless token.valid?

class Token

  include ::ActiveModel::Validations

  validate :token_validation

  def initialize(options = {})
    @bearer = options[:bearer] || '' # "Bearer zxcasdqwesdfsdfqwe"
  end

  # Generate an encoded Json Web Token to send to client app
  # as part of the authentication/authorization process
  # Additional options can be encoded inside the token
  # options = { "mobile" => "+85212345678" }
  def generate(options = {})
    now = Time.now
    options.merge!({
      "iat"     => now.to_i,
      "iss"     => issuer,
      "exp"     => (now + validity).to_i,
    })
    JWT.encode(options.stringify_keys, secret_key, hmac_sha_algo)
  end

  # Allow access to the data stored inside the token e.g. mobile number
  def data
    token
  end

  private

  def jwt_string
    @jwt_string ||= @bearer.sub("Bearer ","")
  end

  # Decode the json web token when we receive it from the client
  def token
    @token ||= JWT.decode(jwt_string, secret_key, hmac_sha_algo)
  end

  # Is the JWT token authentic?
  # - exp should be in the future
  # - iat should be in the past
  def token_validation
    if !jwt_string.blank? && !(token.all? &:blank?)
      cur_time = Time.now
      iat_time = Time.at(token["iat"])
      exp_time = Time.at(token["exp"])
      if exp_time < cur_time
        errors.add(:base, I18n.t('token.expired'))
      elsif !(iat_time < cur_time && iat_time < exp_time)
        errors.add(:base, I18n.t('token.invalid'))
      end
    else
      errors.add(:base, I18n.t('token.invalid'))
    end
  rescue JWT::DecodeError
    errors.add(:base, I18n.t('token.invalid'))
  end

  def jwt_config
    Rails.application.secrets.jwt
  end

  # Key used to generate tokens. MUST be private. Changing this will invalidate all tokens.
  def secret_key
    jwt_config['secret_key']
  end

  def hmac_sha_algo
    jwt_config['hmac_sha_algo']
  end

  def issuer
    jwt_config['issuer']
  end

  # Number of seconds the token is valid for
  def validity
    jwt_config['validity']
  end

end
