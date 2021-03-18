# frozen_string_literal: true
# PIN Manager Library
class PinManager
  def self.formulate_auth_key(mobile, user_id, app_name)
    instance = new(mobile, user_id, app_name)
    return instance.send_pin_for_new_mobile_number if user_id

    instance.send_pin_for_login
  end

  def initialize(mobile, user_id, app_name)
    @mobile = Mobile.new(mobile)
    @mobile_raw = mobile
    @app_name = app_name
    @user = User.find_by(id: user_id) || User.find_by_mobile(@mobile_raw)
  end

  def send_pin_for_login
    validate!
    @user.send_verification_pin(@app_name, @mobile_raw)
    @user.most_recent_token.otp_auth_key
  end

  def send_pin_for_new_mobile_number
    validate!
    mobiles = User.where(mobile: @mobile_raw)
    raise Goodcity::InvalidParamsError.with_text(I18n.t('errors.mobile.already_exists')) if mobiles.exists?

    @user.send_verification_pin(@app_name, @mobile_raw)
    @user.most_recent_token.otp_auth_key
  end

  private

  def allowed_to_login?
    @user&.allowed_login?(@app_name)
  end

  def validate!
    raise Goodcity::InvalidMobileError unless @mobile.valid?
    raise Goodcity::AccessDeniedError if @user.nil?
    raise Goodcity::AccessDeniedError unless allowed_to_login?
  end
end
