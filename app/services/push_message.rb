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
      # TODO
      # Recipient will be now list of userIds so we would be
      # sending message to a common channel rather than a separate
      # channel, All the subscribed users will be allowed to listen to that
      # channel
      @channel = "user_#{@message.recipient_id}"
    end
    @event = 'message'
    @data = serialize(@message)
    super
  end

  private

  def serialize(message)
    Api::V1::MessageSerializer.new(message)
  end

end
