 class PushMessage < PushService

  attr_accessor :message

  def initialize(options = {})
    @message = options[:message]
    @channel = options[:channel]
    super(options)
  end

  def notify
    @message.state = "unread"
    @event = 'update_store'
    @data = serialize(@message)
    super
  end

  private

  def serialize(message)
    Api::V1::MessageSerializer.new(message)
  end
end
