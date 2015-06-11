class ApplicationController < ActionController::API

  include CanCan::ControllerAdditions
  include TokenValidatable

  check_authorization

  # User.current is required to be set for OffersController.before_filter
  before_action :set_locale, :current_user
  helper_method :current_user

  protected

  def app_name
    request.headers['X-GOODCITY-APP-NAME'] || meta_info["appName"]
  end

  def meta_info
    meta = request.headers["X-META"].try(:split, "|")
    meta ? Hash[*meta.flat_map{|a| a.split(":")}] : {}
  end

  def app_version
    request.headers['X-GOODCITY-APP-VERSION']
  end

  def app_sha
    request.headers['X-GOODCITY-APP-SHA']
  end

  private

  def set_locale
    I18n.locale = http_accept_language.compatible_language_from(I18n.available_locales) || "en"
  end

  def current_user
    @current_user ||= begin
      user = nil
      User.current_user = nil
      if token.valid?
        user_id = token.data[0]["user_id"]
        user = User.find_by_id(user_id) if user_id.present?
        User.current_user = user
      end
      user
    end
  end

end
