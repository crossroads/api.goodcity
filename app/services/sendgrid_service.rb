class SendgridService
  attr_accessor :user, :template_name, :substitution_hash

  MAIL_METHODS = %w[send_appointment_confirmation_email send_order_delivery_email send_order_pickup_email]

  def initialize(user)
    @user = user
    @mail ||= SendGrid::Mail.new
    @substitution_hash = {}
    @add_bcc = false
  end

  def set_personalizaton_variables
    @personalization = SendGrid::Personalization.new
    @personalization.to = sendgrid_email_formation(user.email)
    @personalization.bcc = sendgrid_email_formation(ENV["BCC_EMAIL"], I18n.t("email_from_name")) if @add_bcc
    @mail.personalizations = @personalization
    @mail.personalizations[0]["dynamic_template_data"] = substitution_hash
  end

  def send_email
    if send_to_sendgrid?
      sendgrid_instance.client.mail._("send").post(request_body: mail.to_json)
    end

    message = "SlackSMS ('#{user.email}') #{message_body}"
    SlackMessageJob.perform_later(message, ENV["SLACK_PIN_CHANNEL"])
  end

  def send_pin_email
    return unless user.email.present?
    pin = user.most_recent_token.otp_code
    substitution_hash["pin"] = pin
    @mail.template_id = ENV[pin_template_id]
    @mail.from = sendgrid_email_formation(ENV["FROM_EMAIL"], I18n.t("email_from_name"))
    send_email
  end

  MAIL_METHODS.each do |method|
    define_method method.to_sym do |order|
      return unless user.email.present?
      @add_bcc = true
      substitution_hash.merge!(user.email_properties)
      substitution_hash.merge!(order.email_properties)
      @mail.from = sendgrid_email_formation(ENV["APPOINTMENT_FROM_EMAIL"], I18n.t("email_from_name"))
      @mail.template_id = template_id(method)
      send_email
    end
  end

  def template_id(method)
    case method
    when "send_appointment_confirmation_email"
      ENV[appointment_template_id]
    when "send_order_delivery_email"
      ENV[delivery_template_id]
    when "send_order_pickup_email"
      ENV[pickup_template_id]
    end
  end

  def delivery_template_id
    I18n.locale == :en ? "SENDGRID_DELIVERY_TEMPLATE_ID_EN" : "SENDGRID_DELIVERY_TEMPLATE_ID_ZH_TW"
  end

  def pickup_template_id
    I18n.locale == :en ? "SENDGRID_PICKUP_TEMPLATE_ID_EN" : "SENDGRID_PICKUP_TEMPLATE_ID_ZH_TW"
  end

  def pin_template_id
    I18n.locale == :en ? "SENDGRID_PIN_TEMPLATE_ID_EN" : "SENDGRID_PIN_TEMPLATE_ID_ZH_TW"
  end

  def appointment_template_id
    "SENDGRID_APPOINTMENT_TEMPLATE_ID"
  end

  def mail
    set_personalizaton_variables
    @mail
  end

  def sendgrid_instance
    @sengrid_instance ||= SendGrid::API.new(api_key: ENV["SENDGRID_API_KEY"])
  end

  def sendgrid_email_formation(email, name = nil)
    SendGrid::Email.new(email: email, name: name)
  end

  private

  def message_body
    pin = user.most_recent_token.otp_code
    I18n.t("twilio.browse_sms_verification_pin", pin: pin)
  end

  def send_to_sendgrid?
    Rails.env.production? || Rails.env.staging?
  end
end
