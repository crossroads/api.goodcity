class UnauthorizedController < ActionController::Metal
  include ActionController::UrlFor
  include ActionController::Redirecting
  include Rails.application.routes.url_helpers
  include Rails.application.routes.mounted_helpers

  def self.call(env)
    @respond ||= action(:respond)
    @respond.call(env)
  end

  def respond
    unless request.get?
      message = env['warden.options'].fetch(:message, "unauthorized.user")
      # I18n.t(message)
    end
  end
end
