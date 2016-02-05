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
    unless token.valid? && valid_current_user
      throw(:warden, { status: :unauthorized, message: token.errors.full_messages.join })
    end
  end

  def valid_current_user
    User.current_user.present? && !User.current_user.disabled
  end

  def token
    @token ||= Token.new( bearer: request.headers['Authorization'] )
  end

end
