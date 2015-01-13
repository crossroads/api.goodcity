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
    [channel].flatten.in_groups_of(10, false) do |subarray_of_channels|
      PusherJob.perform_later(subarray_of_channels, event, data.to_json)
    end
  end

  #new offer to reviewers
  #first reviewer message to supervisors
  #new message to subscribed users
  #offer status change to donor
  #item rejected/accepted to donor
  def send_notification(text:, entity_type:, entity:, channel:)
    @channel = channel
    @event = "notification"
    @data = {text: text, entity_type: entity_type, entity: entity, date: Time.now}
    notify
  end
end
