class ApplicationController < ActionController::API
  include CanCan::ControllerAdditions
  include TokenValidatable
  include AppMatcher

  check_authorization

  # User.current is required to be set for OffersController.before_filter
  before_action :set_locale, :set_device_id, :current_user
  helper_method :current_user


  protected

  def app_version
    request.headers['X-GOODCITY-APP-VERSION']
  end

  def app_sha
    request.headers['X-GOODCITY-APP-SHA']
  end

  def device_id
    request.headers["X-GOODCITY-DEVICE-ID"]
  end

  private

  def set_locale
    I18n.locale = http_accept_language.compatible_language_from(I18n.available_locales) || "en"
  end

  def set_device_id
    User.current_device_id = device_id
  end

  def current_user
    @current_user ||= begin
      user = nil
      User.current_user = nil
      if token.valid?
        user_id = token.data[0]["user_id"]
        user = User.find_by_id(user_id) if user_id.present?
        if user
          return nil if user.disabled
          user.instance_variable_set(:@treat_user_as_donor, true) unless STAFF_APPS.include?(app_name)
          User.current_user = user
        end
      end
      user
    end
  end
end
