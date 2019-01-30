class SocketioSendJob < ActiveJob::Base
  queue_as :push_updates

  def perform(channels, event, data, resync = false)
    url = Rails.application.secrets.socketio_service['url'] + (resync ? '&resync=true' : '')
    Nestful.post url, { rooms: channels, event: event, args:JSON.parse(data) }, format: :json
  end
end
