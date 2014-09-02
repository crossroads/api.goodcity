module TokenValidatable

  extend ActiveSupport::Concern

  included do
    before_action :validate_token
  end

  private

  def validate_token
    unless token.valid?
      throw(:warden, { status: :unauthorized, message: token.errors.full_messages.join, value: false })
    end
  end

  def token
    @token ||= Token.new( bearer: request.headers['Authorization'] )
  end

end
