class PushOffer < PushService
  attr_accessor :offer

  def initialize(options = {})
    @offer = options[:offer]
    super(options)
  end

  def notify_review
    # @channel = 'reviewer'
    @channel = listener_channels
    @event = 'update_store'
    @data = serialize(@offer)
    notify
  end

  private

  def serialize(offer)
    Api::V1::OfferSerializer.new(offer)
  end

  def listener_channels
    Permission.reviewer.users.pluck(:id).map{ |id| "user_#{id}" }
  end

end
