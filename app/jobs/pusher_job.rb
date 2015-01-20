class PusherJob  < ActiveJob::Base
  queue_as :default

  def perform(channels, event, data)
    url = Rails.application.secrets.socketio_service["url"]
    Nestful.post url, {rooms:channels, event:event, args:JSON.parse(data)}, :format => :json
  end
end
