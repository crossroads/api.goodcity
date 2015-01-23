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

    PusherJob.perform_later([channel].flatten, event, data.to_json)
  end

  def send_update_store(channel, data, collapse_key = nil)
    @channel = channel
    @event = "update_store"
    @data = data
    notify

    channel = [channel].flatten.find_all{|c| Channel.user_channel?(c)}
    unless channel.empty?
      entity_type = nil, entity_id = nil
      if collapse_key.nil?
        entity_type = data[:item].object.class.name
        entity_id = data[:item].id
      else
        # collapse_key should be in the format of "#{entity_type}#{entity_id}"
        entity_id = collapse_key.scan(/\d+/).first.to_i
        entity_type = collapse_key.sub(collapse_key.to_s, "")
      end
      operation = data[:operation].to_s
      data = {event:'update_store', entity_type:entity_type, entity_id:entity_id, operation:operation, date:Time.now.to_json.tr('"','')}
      AzureNotifyJob.perform_later(channel, {data: data}, collapse_key, true)
    end
  end

  # new offer to reviewers
  # first reviewer message to supervisors
  # new message to subscribed users
  # todo: offer accepted
  def send_notification(text:, entity_type:, entity:, channel:)
    # ActiveJob::Serializer doesn't support Time so convert to string
    data = {text: text, entity_type: entity_type, date: Time.now.to_json.tr('"','')}

    @channel = channel
    @event = "notification"
    @data = data.merge({entity: entity})
    notify

    if Channel.user_channel?(channel)
      data = data.merge({event:'notification', entity_id: entity.id})
      AzureNotifyJob.perform_later(channel, {data: data})
    end
  end
end
