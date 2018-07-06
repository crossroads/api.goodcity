class SlackMessageJob < ActiveJob::Base
  queue_as :low

  def perform(message, channel)
    client = Slack::Web::Client.new
    client.chat_postMessage(channel: channel, text: message, as_user: true)
  end

end
