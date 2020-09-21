#
# A class to handle JWT token encode/decode/verification
#
# Initialize token with request header e.g. Token.new( bearer: request.headers['Authorization'] )
# Call token.valid? and token.errors
# E.g. throw(:warden, { status: :unauthorized, message: token.errors.full_messages.join }) unless token.valid?

class Token
  include ::ActiveModel::Validations

  validate :token_validation

  attr_reader :jwt_config

  GC_METADATA_NAMESPACE = "https://goodcity.hk/jwt/metadata"

  module Types
    API = "api".freeze      # An 'api' token is used as a mean of resolving the current user when connecting to the REST API
    OTP = "otp".freeze      # An 'otp' token is designed to be used once during the auth process
  end

  DEFAULT_TYPE  = Types::API
  ALL_TYPES     = [Types::API, Types::OTP].freeze

  #
  # Token class initializer
  #
  # @param [Hash] options
  # @option options [String] :bearer The bearer token to parse
  # @option options [Hash] :jwt_config The JWT options (secret, algo, ...)
  #
  def initialize(options = {})
    @jwt_config = options[:jwt_config]  || Rails.application.secrets.jwt
    @bearer     = options[:bearer]      || '' # "Bearer zxcasdqwesdfsdfqwe"
  end

  # Generate an encoded Json Web Token to send to client app
  # as part of the authentication/authorization process
  # Additional options can be encoded inside the token
  # params = { "mobile" => "+85212345678" }
  def generate(params, metadata: {}, validity: nil, type: DEFAULT_TYPE)
    now       = Time.now.to_i
    validity  ||= default_validity(type)    

    payload = params.merge({
      "iat": now,
      "iss": issuer,
      "exp": now + validity,

      GC_METADATA_NAMESPACE => { type: type }.merge(metadata.stringify_keys)
    })
    JWT.encode(payload.stringify_keys, secret_key, hmac_sha_algo)
  end

  def generate_api_token(params, metadata: {}, validity: nil)
    generate(params, metadata: metadata, validity: validity, type: Types::API)
  end

  def generate_otp_token(params, metadata: {}, validity: nil)
    generate(params, metadata: metadata, validity: validity, type: Types::OTP)
  end

  # Allow access to the data stored inside the token e.g. mobile number
  def data
    token
  end

  def read(key, default: nil)
    data[0][key] || default
  end

  def metadata
    @metadata ||= read(GC_METADATA_NAMESPACE, default: {}).symbolize_keys
  end

  def access_type
    metadata[:type] || DEFAULT_TYPE
  end

  def api?
    access_type == Types::API
  end

  def otp?
    access_type == Types::OTP
  end

  private

  def jwt_string
    @jwt_string ||= @bearer.sub("Bearer ", "")
  end

  # Decode the json web token when we receive it from the client
  def token
    @token ||= JWT.decode(jwt_string, secret_key, true, verify_expiration: false)
  end

  # Is the JWT token authentic?
  # - exp should be in the future
  # - iat should be in the past
  def token_validation
    if (!jwt_string.blank? && !(token.all? &:blank?))
      cur_time = Time.now
      iat_time = Time.at read("iat")
      exp_time = Time.at read("exp")
      return errors.add(:base, I18n.t('token.invalid')) unless ALL_TYPES.include?(access_type)
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
  def default_validity(type)
    return jwt_config['validity_for_otp'].to_i if type == Types::OTP
    return jwt_config['validity'].to_i
  end
end
