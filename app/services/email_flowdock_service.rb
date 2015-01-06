class EmailFlowdockService

  attr_accessor :user

  def initialize(user)
    @user = user
  end

  def send_otp
    token = @user.most_recent_token
    FlowdockNotificationJob.perform_later(token)
  end

end
