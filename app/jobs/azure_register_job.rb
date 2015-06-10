class AzureRegisterJob < ActiveJob::Base
  queue_as :default

  def perform(handle, channel, platform)
    AzureNotificationsService.new.register_device handle, channel, platform
  end
end
