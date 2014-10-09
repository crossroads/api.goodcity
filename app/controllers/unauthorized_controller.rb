class UnauthorizedController < ActionController::Metal
  include ActionController::UrlFor
  include ActionController::RackDelegation
  include ActionController::Redirecting
  include AbstractController::Rendering
  include ActionController::Renderers::All

  def self.call(env)
    @respond ||= action(:respond)
    @respond.call(env)
  end

  def warden_options
    request.env["warden.options"]
  end

  def warden_message
    @message ||= (warden_options.fetch(:message, I18n.t("warden.unauthorized")))
  end

  def respond
    self.status = warden_options.fetch(:status, 401)
    self.content_type = request.format.to_s
    self.response_body = { :error => warden_message }.to_json
  end
end
