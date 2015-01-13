class EmailFlowdockService

  attr_accessor :user

  def initialize(user)
    @user = user
  end

  def send_otp
    token = @user.most_recent_token
    FlowdockNotification.otp(token).deliver_later
  end

end
