class PushService

  class PushServiceError < StandardError; end

  attr_accessor :channel, :event, :data, :resync

  def initialize(options = {})
    @channel = options[:channel]
    @event   = options[:event]
    @data    = options[:data]
    @resync  = options[:resync] || false
  end

  def notify
    %w(channel event data).each do |opt|
      raise PushServiceError, "'#{opt}' has not been set" if send(opt).blank?
    end

    PusherJob.perform_later([channel].flatten, event, data.to_json, resync)
  end

  def send_update_store(channel, data)
    @channel = channel
    @event   = "update_store"
    @data    = data
    @resync  = true
    notify
  end

  # new offer to reviewers
  # first reviewer message to supervisors
  # new message to subscribed users
  # todo: offer accepted
  def send_notification(text:, entity_type:, entity:, channel:, is_admin_app: false, call:nil)

    @channel = channel
    @event   = "notification"
    @data    = pusher_data(text, entity_type, entity, call)
    notify

    if Channel.user_channel?(channel)
      AzureNotifyJob.perform_later(channel, notification_data(text, entity), is_admin_app)
    end
  end

  def pusher_data(text, entity_type, entity, call=nil)
    # ActiveJob::Serializer doesn't support Time so convert to string
    {
      text: text,
      entity_type: entity_type,
      date: Time.now.to_json.tr('"',''),
      entity: entity,
      call: call
    }
  end

  def notification_data(text, entity)
    {
      message:    text,
      offer_id:   entity.offer_id,
      item_id:    entity.item_id,
      is_private: entity.is_private
    }
  end
end
