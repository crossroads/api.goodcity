class PusherJob  < ActiveJob::Base
  queue_as :default

  def perform(subarray_of_channels, event, data)
    Pusher.trigger(subarray_of_channels, event, data)
  end
end
