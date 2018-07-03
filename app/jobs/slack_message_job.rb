class SlackMessageJob < ActiveJob::Base
  queue_as :low

  def perform(message)
    # Slack.send_message(message)
    Rails.logger.info "Sending Slack message: #{message}"
  end

end
