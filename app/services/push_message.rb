class PushMessage < PushService

  attr_accessor :message

  def initialize(options = {})
    @message = options[:message]
    super(options)
  end

  def notify_new_message
    @channel = "user_#{@message.recipient_id}"
    @event = 'message'
    @data = serialize(@message)
    notify
  end

  private

  def serialize(message)
    Api::V1::MessageSerializer.new(message)
  end

end
