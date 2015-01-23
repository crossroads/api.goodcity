class AzureNotifyJob < ActiveJob::Base
  queue_as :default

  def perform(channel, data, collapse_key = nil, delay_while_idle = false)
    AzureNotificationsService.new.notify channel, data, collapse_key, delay_while_idle
  end
end
