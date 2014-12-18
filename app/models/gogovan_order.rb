class GogovanOrder < ActiveRecord::Base
  include Paranoid
  include PushUpdates

  has_one :delivery
  before_destroy :cancel_order

  def self.save_booking(booking_id)
    create(status: 'pending', booking_id: booking_id)
  end

  def self.place_order(user, attributes)
    Gogovan.new(user, attributes).get_order_price
  end

  def self.book_order(user, attributes)
    book_order = Gogovan.new(user, attributes).confirm_order
    save_booking(book_order['id'])
  end

  def update_status(status)
    update_column(:status, status)
  end

  private

  def cancel_order
    Gogovan.cancel_order(booking_id)
    update_status('cancelled')
  end

  #required by PusherUpdates module
  def donor_user_id
    delivery.offer.created_by_id
  end
end
