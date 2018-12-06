require 'twilio-ruby'
class TwilioService

  attr_accessor :user

  def initialize(user)
    @user = user
  end

  def sms_verification_pin(app_name)
    return unless allowed_to_send?
    options = {to: @user.mobile, body: pin_sms_text(app_name)}
    TwilioJob.perform_later(options)
  end

  def send_welcome_msg
    return unless allowed_to_send?
    options = { to: @user.mobile, body: welcome_sms_text }
    TwilioJob.perform_later(options)
  end

  def order_confirmed_sms_to_charity(order)
    return unless allowed_to_send?
    options = { to: @user.mobile, body: new_order_confirmed_text_to_charity(order) }
    TwilioJob.perform_later(options)
  end

  def order_submitted_sms_to_order_fulfilment_users(order)
    return unless allowed_to_send?
    options = { to: @user.mobile, body: new_order_placed_text_to_users(order) }
    TwilioJob.perform_later(options)
  end

  def new_offer_alert(offer)
    return unless allowed_to_send?
    options = {to: @user.mobile, body: new_offer_message(offer)}
    TwilioJob.perform_later(options)
  end

  def send_unread_message_reminder(url)
    return unless allowed_to_send?
    options = { to: @user.mobile, body: unread_message_reminder(url) }
    TwilioJob.perform_later(options)
  end

  private

  def pin_sms_text(app_name)
    pin = user.most_recent_token.otp_code
    if app_name == BROWSE_APP
      I18n.t('twilio.browse_sms_verification_pin', pin: pin)
    else
      I18n.t('twilio.sms_verification_pin', pin: pin)
    end
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

  def new_order_placed_text_to_users(order)
    I18n.t('twilio.order_submitted_sms_to_order_fulfilment_users',
      code: order.code, submitter_name: order.submitted_by.full_name, organisation_name: order.organisation.try(:name_en))
  end

  def new_order_confirmed_text_to_charity(order)
    I18n.t('twilio.new_order_submitted_sms_to_charity',
      code: order.code)
  end

  def unread_message_reminder(url)
    I18n.t('twilio.unread_message_sms', url: url)
  end
end
