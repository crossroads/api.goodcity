class GogovanOrder < ActiveRecord::Base
  include Paranoid
  include PushUpdates

  has_one :delivery, inverse_of: :gogovan_order

  before_create :generate_uuid
  after_commit :start_polling_status, on: [:create]
  before_destroy :cancel_order, if: :pending?

  def self.place_order(user, attributes)
    attributes = set_vehicle_type(attributes) if attributes['offerId']
    Gogovan.new(user, attributes).get_order_price
  end

  def self.book_order(user, attributes)
    order = create(status: 'pending')
    attributes["ggv_uuid"] = order.ggv_uuid
    attributes = set_vehicle_type(attributes) if attributes['offerId']
    book_order = Gogovan.new(user, attributes).confirm_order
    order.update_booking(book_order['id'])
    order
  end

  def update_booking(booking_id)
    update_column(:booking_id, booking_id)
  end

  def update_status(status)
    update_column(:status, status)
  end

  def need_polling?
    status == "active" || status == "pending"
  end

  def pending?
    status == "pending"
  end

  def cancelled?
    status_changed?(to: "cancelled")
  end

  def can_cancel?
    pending? # only cancel orders in this state
  end

  # '200' Fixnum
  # {:error=>"Failed.  Response code = 409.  Response message = Conflict.  Response Body = {\"error\":\"Order that is already accepted by a driver cannot be cancelled\"}."}
  def cancel_order
    if booking_id
      result = Gogovan.cancel_order(booking_id)
      if result == 200
        update_status('cancelled')
      else
        result[:error]
      end
    end
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

  #required by PusherUpdates module
  def offer
    delivery.try(:offer)
  end

  private

  def generate_uuid
    self.ggv_uuid = SecureRandom.uuid[0,6]
  end

  def start_polling_status
    PollGogovanOrderStatusJob.set(wait: GGV_POLL_JOB_WAIT_TIME).
      perform_later(id)
  end

  def self.set_vehicle_type(attributes)
    offer = Offer.find(attributes["offerId"])
    attributes["vehicle"] = offer.gogovan_transport.vehicle_tag
    attributes
  end

  #required by PusherUpdates module
  def offer
    delivery.try(:offer)
  end
end
