require 'twilio-ruby'
class TwilioService

  attr_accessor :user

  def initialize(user)
    @user = user
  end

  def sms_verification_pin(app_name)
    send_sms(body: pin_sms_text(app_name))
  end

  def send_welcome_msg
    user_name = User.current_user&.full_name.presence
    send_sms(body: welcome_sms_text(user_name)) if user_name
  end

  def order_confirmed_sms_to_charity(order)
    send_sms(body: new_order_confirmed_text_to_charity(order))
  end

  def order_submitted_sms_to_order_fulfilment_users(order)
    send_sms(body: new_order_placed_text_to_users(order))
  end

  def send_unread_message_reminder(url)
    send_sms(body: unread_message_reminder(url))
  end

  # options[:to] = "+85261111111"
  # options[:body] = "SMS body"
  def send_sms(options)
    options = {to: @user.mobile}.merge(options)
    if send_to_twilio?
      TwilioJob.perform_later(options)
    elsif options[:to].presence
      message = "SlackSMS (to: #{options[:to]}, id: #{user.id}, full_name: #{user.full_name}) #{options[:body]}"
      SlackMessageJob.perform_later(message, ENV['SLACK_PIN_CHANNEL'])
    end
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

  # On production env, send real SMS
  # In all other environments, send to Slack
  def send_to_twilio?
    Rails.env.production?
  end

  def welcome_sms_text(user_name)
    I18n.t('twilio.charity_user_welcome_sms',
      full_name: user_name)
  end

  def new_order_placed_text_to_users(order)
    I18n.t('twilio.order_submitted_sms_to_order_fulfilment_users',
      code: order.code, submitter_name: order.created_by.full_name, organisation_name: order.organisation.try(:name_en))
  end

  def new_order_confirmed_text_to_charity(order)
    I18n.t('twilio.new_order_submitted_sms_to_charity',
      code: order.code)
  end

  def unread_message_reminder(url)
    I18n.t('twilio.unread_message_sms', url: url)
  end
end
