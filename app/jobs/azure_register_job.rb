class AzureRegisterJob < ActiveJob::Base
  queue_as :default

  def perform(handle, channel, platform, app_name)
    AzureNotificationsService.new(app_name).register_device(handle, channel, platform)
  end
end
