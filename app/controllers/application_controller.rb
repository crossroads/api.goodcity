class ApplicationController < ActionController::API
  include ActionController::Helpers
  include CanCan::ControllerAdditions
  include TokenValidatable
  include AppMatcher

  check_authorization
  before_action :set_paper_trail_whodunnit
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
      return nil unless token.valid? && token_data.present?

      user_id = token.read('user_id')
      user = User.find_by_id(user_id)
      return nil unless user.present?
      return nil if user.disabled

      user.instance_variable_set(:@treat_user_as_donor, true) unless STAFF_APPS.include?(app_name)
      User.current_user = user
      user
    end
  end

  def token_data
    token.data && token.data[0]['user_id']
  end

  # For Lograge
  def append_info_to_payload(payload)
    super
    payload[:user_id] = current_user.id if current_user
    payload[:request_ip] = request.remote_ip
    payload[:app_name] = app_name # calling app: donor, admin, stock, browse
    payload[:app_version] = app_version # calling app version
  end
end
