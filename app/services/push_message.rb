class PushMessage < PushService

  attr_accessor :message

  def initialize(options = {})
    @message = options[:message]
    super(options)
  end

  def notify
    if @message.is_private?
      @channel = "supervisors"
    else
      @message.state = "unread"
      @channel = listener_channels(@message)
    end
    @event = 'message'
    @data = serialize(@message)
    super
  end

  private

  def serialize(message)
    Api::V1::MessageSerializer.new(message)
  end

  def listener_channels(message)
    message.subscriptions.subscribed_users(message.sender_id).map { |subscriber|
      "user_#{subscriber}"}
  end
end
