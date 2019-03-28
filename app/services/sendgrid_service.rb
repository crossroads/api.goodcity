class SendgridService
  attr_accessor :user, :template_name, :substitution_hash

  def initialize(user)
    @user = user
    @mail ||= SendGrid::Mail.new
    @substitution_hash = {}
  end

  def set_personalizaton_variables
    @personalization = SendGrid::Personalization.new
    @personalization.to = sendgrid_email_formation(user.email)
    @mail.personalizations = @personalization
    @mail.personalizations[0]["dynamic_template_data"] = substitution_hash
  end

  def send_email
    if send_to_sendgrid?
      sendgrid_instance.client.mail._("send").post(request_body: mail.to_json)
    end
  end

  def send_pin_email
    pin = user.most_recent_token.otp_code
    substitution_hash["pin"] = pin
    @mail.template_id = ENV[template_id_based_on_locale]
    send_email
  end

  def template_id_based_on_locale
    I18n.locale == :en ? "SENDGRID_PIN_TEMPLATE_ID_EN" : "SENDGRID_PIN_TEMPLATE_ID_ZH_TW"
  end

  def mail
    @mail.from = sendgrid_email_formation(ENV["FROM_EMAIL"], I18n.t("email_from_name"))
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

  def send_to_sendgrid?
    Rails.env.production? || Rails.env.staging?
  end
end
