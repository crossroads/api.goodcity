class GogovanOrder < ActiveRecord::Base
  include Paranoid
  include PushUpdates

  has_one :delivery

  after_commit :start_polling_status, on: [:create]

  def self.save_booking(booking_id)
    create(status: 'pending', booking_id: booking_id)
  end

  def self.place_order(user, attributes)
    attributes = set_vehicle_type(attributes) if attributes['offerId']
    Gogovan.new(user, attributes).get_order_price
  end

  def self.book_order(user, attributes)
    attributes = set_vehicle_type(attributes) if attributes['offerId']
    book_order = Gogovan.new(user, attributes).confirm_order
    save_booking(book_order['id'])
  end

  def update_status(status)
    update_column(:status, status)
  end

  def need_polling?
    state == "active" || state == "pending"
  end

  private

  def start_polling_status
    PollGogovanOrderStatusJob.set(wait: 5.seconds).perform_later(self)
  end

  def self.set_vehicle_type(attributes)
    offer = Offer.find(attributes['offerId'])
    attributes['vehicle'] = offer.gogovan_transport.vehical_tag
    attributes
  end

  #required by PusherUpdates module
  def offer
    delivery.try(:offer)
  end
end
