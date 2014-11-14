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
      Pusher.trigger(subarray_of_channels, event, data)
    end
  end

  def update_store(options)
    data = options[:data]
    donor_channel = options[:donor_channel]
    channel = (options[:channel] || Channel.staff)
    channel += donor_channel if donor_channel.present?
    @channel = channel
    @event = "update_store"
    @data = "Api::V1::#{data.class}Serializer".constantize.new(data)
    notify
  end

  #new offer to reviewers
  #first reviewer message to supervisors
  #new message to subscribed users
  #offer status change to donor
  #item rejected/accepted to donor
  # expected options: text, entity_type, entity
  def send_notification(options)
    @channel = options.delete(:channel)
    @event = "notification"
    @data = options.merge(date: Time.now).to_json
    notify
  end
end
