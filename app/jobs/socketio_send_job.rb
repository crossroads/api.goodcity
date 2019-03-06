class SocketioSendJob < ActiveJob::Base
  queue_as :push_updates

  def perform(channels, event, data, resync = false)
    url = Rails.application.secrets.socketio_service['url'] + (resync ? '&resync=true' : '')
    args = JSON.parse(data)
    # send in batches of 20 channels or less
    channels.flatten.each_slice(20) do |channel_slice|
      Nestful.post url, { rooms: channel_slice, event: event, args: args }, format: :json
    end
  end
end
