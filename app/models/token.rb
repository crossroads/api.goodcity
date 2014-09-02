#
# A class to handle JWT token encode/decode/verification
#
# Initialize token with request header e.g. Token.new( bearer: request.headers['Authorization'] )
# Call token.valid? and token.errors
# E.g. throw(:warden, { status: :unauthorized, message: token.errors.full_messages.join, value: false }) unless token.valid?

class Token

  include ::ActiveModel::Validations

  validate :token_validation

  def initialize(options = {})
    @bearer = options[:bearer] || '' # "Bearer zxcasdqwesdfsdfqwe"
  end

  def otp_secret_key
    token['otp_secret_key']
  end

  # Generate an encoded Json Web Token to send to client app
  # on successful completion of the authentication process
  # options = { "mobile" => "12345678" }
  def generate(options = {})
    now = Time.now
    options.merge!({
      "iat"            => now.to_i,
      "iss"            => issuer,
      "exp"            => (now + 14.days).to_i,
      "otp_secret_key" => header
    })
    JWT.encode(options.stringify_keys, secret_key, hmac_sha_algo)
  end

  def header
    @header ||= @bearer.sub("Bearer ","")
  end

  private

  # Decode the json web token when we receive it from the client
  def token
    @token ||= JWT.decode(header, secret_key, hmac_sha_algo)
  end

  # Is the JWT token is authentic?
  # - exp should be in the future
  # - iat should be in the past
  # Time.now should not be more than 14 days, that means time.now and
  # exp should not be equal
  def token_validation
    if !header.blank? && !(token.all? &:blank?)
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
    Rails.logger.info("JWT::DecodeError - could not decode JWT token")
    errors.add(:base, I18n.t('token.invalid'))
  end

  def jwt_config
    Rails.application.secrets.jwt
  end

  def secret_key
    jwt_config['secret_key']
  end

  def hmac_sha_algo
    jwt_config['hmac_sha_algo']
  end

  def issuer
    jwt_config['issuer']
  end

end
