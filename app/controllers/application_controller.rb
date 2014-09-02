class ApplicationController < ActionController::API

  include CanCan::ControllerAdditions
  include TokenValidatable

  rescue_from CanCan::AccessDenied, with: :access_denied

  before_action :set_locale
  helper_method :current_user

  private

  def warden
    request.env['warden']
  end

  def warden_options
    request.env["warden.options"]
  end

  def set_locale
    I18n.locale = http_accept_language.compatible_language_from(I18n.available_locales)
  end

  def current_user
    @current_user ||= begin
      token.valid? ? User.find_all_by_otp_secret_key( token.otp_secret_key ).first : nil
    end
  end

  def access_denied
    if request.format.json?
      throw(:warden, {status: :unauthorized, message: I18n.t('warden.unauthorized'), value: false})
    else
      render(file: "#{Rails.root}/public/403.#{I18n.locale}.html", status: 403, layout: false)
    end
  end

end
