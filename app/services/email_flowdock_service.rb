class EmailFlowdockService

  def self.email_otp(otp)
    FlowdockNotification.otp(otp).deliver
  end

end
