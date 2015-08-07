class SocketioSendJob < ActiveJob::Base
  queue_as :default

  def perform(channels, event, data, resync = false)
    url = Goodcity.config.socketio_service.url + (resync ? '&resync=true' : '')
    Nestful.post url, {rooms:channels, event:event, args:JSON.parse(data)}, format: :json
  end
end
