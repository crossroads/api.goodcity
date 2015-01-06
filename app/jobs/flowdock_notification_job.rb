class FlowdockNotificationJob  < ActiveJob::Base
  queue_as :email

  def perform(options)
    @token = options
    FlowdockNotification.otp(@token).deliver_later
  end
end
