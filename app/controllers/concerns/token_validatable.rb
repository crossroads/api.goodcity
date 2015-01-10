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
    unless token.valid?
      throw(:warden, { status: :unauthorized, message: token.errors.full_messages.join })
    end
  end

  def token
    @token ||= Token.new( bearer: request.headers['Authorization'] )
  end

end
