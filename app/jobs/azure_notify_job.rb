class AzureNotifyJob < ActiveJob::Base
  queue_as :default
  sidekiq_options retry: 3, dead: false # will retry 5 times and then disappear

  def perform(channel, data, app_name)
    AzureNotificationsService.new(app_name).notify(channel, data)
  end
end
