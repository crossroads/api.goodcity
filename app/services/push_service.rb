# require 'pusher'

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

  def self.update_store(data, donor_channel, channel = Channel.staff)
    pusher = PushService.new({
      channel: channel,
      event: "update_store",
      data: "Api::V1::#{data.class}Serializer".constantize.new(data)
    })
    pusher.channel += donor_channel if donor_channel.present?
    pusher.notify()
  end

  #new offer to reviewers
  #first reviewer message to supervisors
  #new message to subscribed users
  #offer status change to donor
  #item rejected/accepted to donor
  def self.send_notification(text, entity_type, entity, channel)
    PushService.new({
      channel: channel,
      event: "notification",
      data: {text: text, entity_type: entity_type, entity: entity, date: Time.now}.to_json
    }).notify()
  end
end
