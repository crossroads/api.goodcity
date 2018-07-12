require 'twilio-ruby'
class TwilioService

  attr_accessor :user

  def initialize(user)
    @user = user
  end

  def sms_verification_pin
    return unless allowed_to_send?
    options = {to: @user.mobile, body: pin_sms_text}
    TwilioJob.perform_later(options)
  end

  def send_welcome_msg
    return unless allowed_to_send?
    options = { to: @user.mobile, body: welcome_sms_text }
    TwilioJob.perform_later(options)
  end

  def send_new_order_sms(order)
    return unless allowed_to_send?
    options = { to: @user.mobile, body: new_order_text(order) }
    TwilioJob.perform_now(options)
  end

  def new_offer_alert(offer)
    return unless allowed_to_send?
    options = {to: @user.mobile, body: new_offer_message(offer)}
    TwilioJob.perform_later(options)
  end

  private

  def pin_sms_text
    pin = user.most_recent_token.otp_code
    I18n.t('twilio.sms_verification_pin', pin: pin)
  end

  def new_offer_message(offer)
    creator = offer.created_by
    name = "#{creator.first_name} #{creator.last_name}"
    "#{name} submitted new offer."
  end

  # Whitelisting happens only on staging.
  # On live, ALL mobiles are allowed
  def allowed_to_send?
    return true if Rails.env.production?
    mobile = @user.mobile
    ENV['VALID_SMS_NUMBERS'].split(",").map(&:strip).include?(mobile)
  end

  def welcome_sms_text
    I18n.t('twilio.charity_user_welcome_sms',
      full_name: User.current_user.full_name)
  end

  def new_order_text(order)
    I18n.t('twilio.new_order_submitted_sms',
      code: order.code)
  end
end
