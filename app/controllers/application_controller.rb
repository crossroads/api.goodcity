class ApplicationController < ActionController::API

  include CanCan::ControllerAdditions
  include TokenValidatable

  check_authorization

  before_action :set_locale
  helper_method :current_user
  before_filter :current_user # User.current is required to be set for OffersController.before_filter

  private

  def set_locale
    I18n.locale = http_accept_language.compatible_language_from(I18n.available_locales) || 'en'
  end

  def current_user
    @current_user ||= begin
      user = nil
      User.current_user = nil
      if token.valid?
        user_id = token.data['user_id']
        user = User.find_by_id(user_id) if user_id.present?
        User.current_user = user
      end
      user
    end
  end

end
