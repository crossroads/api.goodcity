module TokenValidatable
  extend ActiveSupport::Concern

  included do
    before_action :validate_token
  end

  def generate_token(options={})
    Token.new.generate(options)
  end

  private

  def validate_token
    unless token.valid? and token.api?
      raise Goodcity::UnauthorizedError.with_text(token.errors.full_messages.join)
    end
  end

  def token
    @token ||= Token.new( bearer: request.headers['Authorization'] )
  end
end
