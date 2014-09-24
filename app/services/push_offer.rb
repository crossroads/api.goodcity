class PushOffer < PushService
  attr_accessor :offer

  def initialize(options = {})
    @offer = options[:offer]
    super(options)
  end

  def notify_review
    # @channel = 'reviewer'
    @channel = listener_channels(@message)
    @event = 'update_store'
    @data = serialize(@offer)
    notify
  end

  private

  def serialize(offer)
    Api::V1::OfferSerializer.new(offer)
  end

  def listener_channels(message)
    User.get_by_permission(Permission.reviewer.id).pluck(:id).map { |subscriber|
      "user_#{subscriber}"}
  end

end
