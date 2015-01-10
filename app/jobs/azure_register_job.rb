class AzureRegisterJob < ActiveJob::Base
  queue_as :default

  def perform(handle, channel)
    AzureNotificationsService.new.register_device handle, channel
  end
end
