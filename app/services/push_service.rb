require 'pusher'

class PushService

  class PushServiceError < StandardError; end

  attr_accessor :channel, :event, :message

  def initialize(options = {})
    @channel = options[:channel]
    @event = options[:event]
    @message = options[:message]
  end

  def notify
    %w(channel event message).each do |opt|
      raise PushServiceError, "'#{opt}' has not been set" if send(opt).blank?
    end
    Pusher.trigger(channel, event, message)
  end

end
