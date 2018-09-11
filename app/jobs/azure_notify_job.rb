class AzureNotifyJob < ActiveJob::Base
  queue_as :default

  def perform(channel, data, app_name)
    AzureNotificationsService.new(app_name).notify(channel, data)
  end
end
