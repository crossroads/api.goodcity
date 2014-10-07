class PushOffer < PushService
  attr_accessor :offer

  def initialize(options = {})
    @offer = options[:offer]
    super(options)
  end

  def notify_review
    @channel = listener_channels
    @event = 'update_store'
    @data = serialize(@offer)
    notify if @channel.any?
  end

  private

  def serialize(offer)
    Api::V1::OfferSerializer.new(offer)
  end

  def listener_channels
    User.reviewers.map{ |user| "user_#{user.id}" }
  end

end
