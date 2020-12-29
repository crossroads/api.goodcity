class Gogox

  attr_accessor :params, :time, :vehicle, :district_id

  VEHICLE_TYPES = ["van", "mudou", "mudou9"]

  def initialize(options = {})
    @params        = options
    @time         = parse_pickup_time(options[:pickup_scheduled_at])
    @vehicle      = options[:vehicle]
    @district_id  = options[:district_id]
  end

  # Rsponse
  # {
  #   "uuid" => "2f859363-5c43-4fe2-9b91-6c6c43d610d2",
  #   "status" => "pending",
  #   "vehicle_type" => "van",
  #   "payment_method" => "prepaid_wallet",
  #   "courier" => {},
  #   "pickup" => {
  #     "name" => "Swati J",
  #     "street_address" => "123",
  #     "floor_or_unit_number" => nil,
  #     "schedule_at" => 1609242940,
  #     "location" => {"lat" => 22.5029632, "lng" => 114.1277213},
  #     "contact" => {
  #       "name" => "Swati J",
  #       "phone_number" => "+85251111113",
  #       "phone_extension" => nil
  #     }
  #   },
  #   "destinations" => [{
  #     "name" => "Steve Kenworthy",
  #     "street_address" => "Castle Peak Rd (So Kwun Wat)",
  #     "floor_or_unit_number" => nil,
  #     "location" => {"lat" => 22.3748365, "lng" => 113.9931416},
  #     "contact" => {
  #       "name" => "Steve Kenworthy",
  #       "phone_number" => "+85251111111"
  #     }
  #   }],
  #   "note_to_courier" => nil,
  #   "price" => {"amount" => 15000, "currency" => "HKD"},
  #   "price_breakdown" => [{"key" => "fee", "amount" => 15000}]
  # }
  def book
    GogoxApi::Transport.new(params: order_attributes).order
  end

  # Response:
  # {
  #   "vehicle_type" => "van",
  #   "estimated_price" => {"amount" => 15000, "currency" => "HKD"},
  #   "estimated_price_breakdown" => [{"key" => "fee", "amount" => 15000}]
  # }
  def quotation
    GogoxApi::Transport.new(params: quotation_attributes).quotation
  end

  class << self

    def transport_status(booking_id)
      GogoxApi::Transport.new.status(booking_id)
    end

    # Response
    # Response is nil on successful cancellation of GOGOX transport
    def cancel_order(booking_id)
      GogoxApi::Transport.new.cancel(booking_id)
    end

  end

  private

  def order_attributes
    {
      'vehicle_type': vehicle_type,
      "pickup_location": pickup_location,
      "pickup_street_address": params[:pickup_street_address],
      "pickup_scheduled_at": parse_time,
      "pickup_contact_name": params[:pickup_contact_name],
      "pickup_contact_phone": params[:pickup_contact_phone],
      "destination_location": destination_location,
      "destination_street_address": destination_street_address,
      "destination_contact_name": destination_contact_name,
      "destination_contact_phone": destination_contact_phone
    }
  end

  def quotation_attributes
    {
      'vehicle_type': vehicle_type,
      "pickup_scheduled_at": parse_time,
      "pickup_location": pickup_location,
      "destination_location": destination_location
    }
  end

  def destination_location
    [22.3748365, 113.9931416]
  end

  def destination_street_address
    "Castle Peak Rd (So Kwun Wat)"
  end

  def destination_contact_name
    "Steve Kenworthy"
  end

  def destination_contact_phone
    "+85251111111"
  end

  def pickup_location
    raise(ValueError, "Provide valid district_id") if @district_id.nil?

    pickup_district = District.find(@district_id)
    [pickup_district.latitude, pickup_district.longitude]
  end

  def vehicle_type
    if vehicle.blank? || !VEHICLE_TYPES.include?(vehicle)
      raise(ValueError, "vehicle should be from #{VEHICLE_TYPES.join(', ')}")
    end
    vehicle
  end

  def parse_pickup_time(time = nil)
    return time if time.present?

    # next available date within next 5 days
    next_available_date = DateSet.new(5, 1).available_dates.first
    (next_available_date.beginning_of_day + 12.hours)
  end

  def parse_time
    DateTime.parse(@time.to_s).to_i
  end

  class ValueError < StandardError; end
end
