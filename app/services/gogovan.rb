class Gogovan

  attr_accessor :user, :name, :mobile, :time, :need_english,
    :need_cart, :need_carry, :district_id

  def initialize(user, options = {})
    @user         = user
    @name         = options['name']
    @mobile       = options['mobile']
    @time         = options['pickupTime']
    @need_english = options['needEnglish']
    @need_cart    = options['needCart']
    @need_carry   = options['needCarry']
    @district_id  = options['districtId']
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

  private

  def order_attributes
    {
      order: {
        name:           @name || @user.full_name,
        phone_number:   @mobile || @user.mobile,
        pickup_time:    @time,
        vehicle:        'van',
        locations:      District.location_json(@district_id),
        extra_requirements: {
          need_english: @need_english,
          need_cart:    @need_cart,
          need_carry:   @need_carry
        }
      }
    }
  end
end
