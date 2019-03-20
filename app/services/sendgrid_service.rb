class SendgridService
  attr_accessor :user, :to, :subject, :content, :from

  def intialialize(user, subject, content)
    @user = user
    @to = sendgrid_email_formation(user.email)
    @subject = subject
    @content = content
    @from = sendgrid_email_formation("contact@goodcity.hk")
    @content_type = "text/plain"
  end

  def send_email
    sendgrid_instance.client.mail._("send").post(request_body: mail.to_json)
  end

  def mail #base
    SendGrid::Mail.new(from_email, subject, to_email, content)
  end

  def sendgrid_instance
    @sengrid_instance ||= SendGrid::API.new(api_key: ENV["SENDGRID_API_KEY"])
  end

  def sendgrid_email_formation(email) #base
    SendGrid::Email.new(email: email)
  end
end
