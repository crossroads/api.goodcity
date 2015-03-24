class GogovanOrder < ActiveRecord::Base
  include Paranoid
  include PushUpdates

  has_one :delivery

  after_commit :start_polling_status, on: [:create]
  before_save :push_back_offer_state, if: :is_cancelled?

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
    status == "active" || status == "pending"
  end

  def is_cancelled?
    status_changed?(to: "cancelled")
  end

  def cancel_order
    Gogovan.cancel_order(booking_id)
    update_status('cancelled')
  end

  def push_back_offer_state
    delivery.offer.cancel_schedule
  end

  def assign_details(order_details)
    self.status = order_details["status"]
    self.price = order_details["price"]
    if (driver_details = order_details["driver"])
      self.driver_name = driver_details["name"]
      self.driver_mobile = driver_details["phone_number"]
      self.driver_license = driver_details["license_plate"]
    end
    self
  end

  private

  def start_polling_status
    PollGogovanOrderStatusJob.set(wait: GGV_POLL_JOB_WAIT_TIME).perform_later(self.id)
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
