class GogovanOrder < ActiveRecord::Base
  has_paper_trail class_name: 'Version', meta: { related: :offer }
  include Paranoid
  include PushUpdates

  has_one :delivery, inverse_of: :gogovan_order

  before_create :generate_ggv_uuid
  after_commit :start_polling_status, on: :create
  after_update :notify_order_completed, if: :order_completed?
  before_destroy :cancel_order, if: :pending?

  def self.place_order(user, attributes)
    attributes = set_vehicle_type(attributes)
    Gogovan.new(user, attributes).get_order_price
  end

  def self.book_order(user, attributes)
    order = create(status: 'pending')
    attributes["ggv_uuid"] = order.ggv_uuid
    attributes = set_vehicle_type(attributes)
    update_vehicle_type(attributes)
    book_order = Gogovan.new(user, attributes).confirm_order
    order.update_column(:booking_id, book_order['id'])
    order
  end

  def self.offer_by_ggv_uuid(ggv_uuid)
    offer = find_by(ggv_uuid: ggv_uuid).try(:delivery).try(:offer)
    raise ActiveRecord::RecordNotFound unless offer
    Offer.with_eager_load.find(offer.id)
  end

  def donor
    User.joins(offers: {delivery: :gogovan_order}).
      where('gogovan_orders.id = ?', id).last
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
        update_column(:status, 'cancelled') unless self.destroyed?
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
    self.completed_at = Time.now if(order_details["status"] == "completed")
    self
  end

  # required by PushUpdates and PaperTrail modules
  def offer
    delivery.try(:offer)
  end

  private

  def generate_ggv_uuid
    self.ggv_uuid = SecureRandom.uuid[0,6]
  end

  def start_polling_status
    PollGogovanOrderStatusJob.set(wait: GGV_POLL_JOB_WAIT_TIME).
      perform_later(id)
  end

  def self.set_vehicle_type(attributes)
    attributes["vehicle"] = if(attributes["gogovanOptionId"])
      GogovanTransport.get_vehicle_tag(attributes["gogovanOptionId"])
    elsif(attributes['offerId'])
      Offer.find(attributes["offerId"]).try(:gogovan_transport).try(:vehicle_tag)
    end
    attributes
  end

  def self.update_vehicle_type(attributes)
    if attributes["gogovanOptionId"] && attributes['offerId']
      offer = Offer.find(attributes["offerId"])
      offer && offer.update_column(:gogovan_transport_id, attributes["gogovanOptionId"])
    end
  end

  def notify_order_completed
    message = I18n.t("gogovan.notify_completed", license: driver_license, booking_id: booking_id)

    PushService.new.send_notification Channel.staff, true, {
      category: 'offer_delivery',
      message:   message,
      offer_id:  offer.id,
      author_id: User.system_user
    }
  end

  def order_completed?
    changes.has_key?("status") && changes["status"].last == "completed"
  end

  def pick_up_location
    delivery.try(:contact).try(:address).try(:district).try(:name)
  end
end
