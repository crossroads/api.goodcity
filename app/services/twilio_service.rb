require 'twilio-ruby'
class TwilioService
  attr_accessor :user, :mobile

  def initialize(user, mobile = nil)
    @user = user
    @mobile = mobile || user.mobile
  end

  def sms_verification_pin(app_name, pin: nil)
    send_sms(body: pin_sms_text(app_name, pin: pin))
  end

  def send_welcome_msg
    user_name = @user.full_name.presence
    I18n.with_locale(@user.locale) do
      send_sms(body: welcome_sms_text(user_name)) if user_name
    end
  end

  def order_confirmed_sms_to_charity(order)
    I18n.with_locale(@user.locale) do
      send_sms(body: new_order_confirmed_text_to_charity(order))
    end
  end

  # TODO: Remove this method as its not used anywhere
  def order_submitted_sms_to_order_fulfilment_users(order)
    send_sms(body: new_order_placed_text_to_users(order))
  end

  def send_unread_message_reminder(url)
    I18n.with_locale(@user.locale) do
      send_sms(body: unread_message_reminder(url))
    end
  end

  # options[:to] = "+85261111111"
  # options[:body] = "SMS body"
  def send_sms(options)
    options = { to: mobile }.merge(options)
    TwilioJob.perform_later(options)
  end

  private

  def pin_sms_text(app_name, pin: nil)
    I18n.with_locale(user.locale) do
      pin ||= user.most_recent_token.otp_code
      if app_name == BROWSE_APP
        I18n.t('twilio.browse_sms_verification_pin', pin: pin)
      else
        I18n.t('twilio.sms_verification_pin', pin: pin)
      end
    end
  end

  def welcome_sms_text(user_name)
    I18n.t('twilio.charity_user_welcome_sms',
           full_name: user_name)
  end

  def new_order_placed_text_to_users(order)
    I18n.t('twilio.order_submitted_sms_to_order_fulfilment_users',
           code: order.code, submitter_name: order.created_by.full_name,
           organisation_name: order.organisation.try(:name_en))
  end

  def new_order_confirmed_text_to_charity(order)
    I18n.t('twilio.new_order_submitted_sms_to_charity',
           code: order.code)
  end

  def unread_message_reminder(url)
    I18n.t('twilio.unread_message_sms', url: url)
  end
end
