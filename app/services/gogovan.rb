class Gogovan

  attr_accessor :user, :name, :mobile, :time, :need_english,
    :need_cart, :need_carry, :district_id, :vehicle, :ggv_uuid, :offer

  def initialize(user = nil, options = {})
    @user         = user
    @name         = options['name']
    @mobile       = options['mobile']
    @time         = options['pickupTime'] || get_pickup_date
    @need_english = options['needEnglish']
    @need_cart    = options['needCart']
    @need_carry   = options['needCarry']
    @district_id  = options['districtId']
    @vehicle      = options['vehicle']
    @ggv_uuid     = options['ggv_uuid']
    @offer        = Offer.find_by(id: options['offerId'])
  end

  def initiate_order
    GoGoVanApi::Order.new(nil, order_attributes)
  end

  def confirm_order
    initiate_order.book
  end

  def get_order_price
    initiate_order.price
  end

  def get_status(id)
    GoGoVanApi::Order.new(id).status
  end

  def self.cancel_order(booking_id)
    GoGoVanApi::Order.new(booking_id).cancel
  end

  private

  def order_attributes
    {
      order: {
        name:           @name || @user.full_name,
        phone_number:   @mobile || @user.mobile,
        pickup_time:    parse_time,
        vehicle:        @vehicle,
        locations:      District.location_json(@district_id),
        extra_requirements: {
          need_english: @need_english,
          need_cart:    @need_cart,
          need_carry:   @need_carry,
          remark:       ggv_driver_notes
        }
      }
    }
  end

  def get_pickup_date
    next_available_date = DateSet.new().available_dates.first
    next_available_date.beginning_of_day + 12.hours
  end

  def ggv_driver_notes
    delivery = offer.delivery
    if offer && ggv_uuid
      link = "#{Rails.application.secrets.base_urls["app"]}/ggv_order/#{ggv_uuid}"
      "Ensure you deliver all the items listed: See details #{link}"
    end
  end

  def parse_time
    if @time.is_a?(Time)
      @time
    else
      Time.parse(@time)
    end
  end

end
