require 'pusher'

class PushService

  class PushServiceError < StandardError; end

  attr_accessor :channel, :event, :data

  def initialize(options = {})
    @channel = options[:channel]
    @event = options[:event]
    @data = options[:data]
  end

  def notify
    %w(channel event data).each do |opt|
      raise PushServiceError, "'#{opt}' has not been set" if send(opt).blank?
    end

   [channel].flatten.in_groups_of(10, false){ |subarray_of_channels|
      Pusher.trigger(subarray_of_channels, event, data)
    }
  end
end
