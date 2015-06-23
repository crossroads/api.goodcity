class AzureRegisterJob < ActiveJob::Base
  queue_as :default

  def perform(handle, channel, platform, is_admin_app = false)
    AzureNotificationsService.new(is_admin_app).
      register_device(handle, channel, platform)
  end
end
