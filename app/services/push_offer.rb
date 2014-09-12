class PushOffer < PushService

  attr_accessor :offer

  def initialize(options = {})
    @offer = options[:offer]
    super(options)
  end

  def notify_review
    @channel = 'reviewer'
    @event = 'submit_offer'
    @data = serialize(@offer)
    notify
  end

  private

  def serialize(offer)
    Api::V1::OfferSerializer.new(offer)
  end

end
