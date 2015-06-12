class AzureNotifyJob < ActiveJob::Base
  queue_as :default

  def perform(channel, data, is_admin_app = false)
    AzureNotificationsService.new(is_admin_app).notify(channel, data)
  end
end
