class AzureNotifyJob < ActiveJob::Base
  queue_as :default

  def perform(channel, data)
    AzureNotificationsService.new.notify channel, data
  end
end
