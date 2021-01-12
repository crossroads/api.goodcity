class TransportService

  attr_accessor :provider_name, :params, :provider, :booking_id, :user, :district_id

  def initialize(options={})
    @params = options
    @provider_name = options && options["provider"]
    @provider ||= Object::const_get(provider_name)
    @booking_id = options && options["booking_id"]

    fetch_user
    fetch_district_id
  end

  def quotation
    @provider.new(quotation_attributes).quotation
  end

  def book
    response = @provider.new(order_attributes).book
    storeOrderDetails(response)
  end

  def cancel
    response = @provider.cancel_order(booking_id)
    if response
      updateOrderDetails({
        status: "cancelled",
        order_uuid: booking_id
      })
    end
  end

  def status
    response = @provider.transport_status(booking_id)
    if response
      updateOrderDetails({
        status: response["status"],
        order_uuid: booking_id,
        metadata: response
      })
    end
  end

  private

  def storeOrderDetails(response)
    TransportProviderOrder.create(
      transport_provider_id: TransportProvider.find_by(name: provider_name).try(:id),
      order_uuid: response["uuid"],
      status: response["status"],
      schedule_at: response["pickup"]["schedule_at"],
      metadata: response,
      offer_id: @params["offer_id"]
    )
  end

  def updateOrderDetails(response)
    order = TransportProviderOrder.find_by(order_uuid: response["order_uuid"])
    order.update_attributes(response)
  end

  def quotation_attributes
    {
      'vehicle_type': @params["vehicle_type"],
      "scheduled_at": @params["scheduled_at"],
      "pickup_location": pickup_location,
      "destination_location": destination_location
    }
  end

  def pickup_location
    pickup_district = District.find(@district_id)
    [pickup_district.latitude, pickup_district.longitude]
  end

  # TODO: Update crossroads geolocation values
  def destination_location
    [32.3790365, 120.9001416]
  end

  # TODO: Change
  def destination_street_address
    "Santa Peak Road"
  end

  # TODO: Change
  def destination_contact_name
    "GCAdmin User"
  end

  # TODO: Change
  def destination_contact_phone
    "+85251111111"
  end

  def order_attributes
    {
      'vehicle_type': @params["vehicle_type"],
      "pickup_location": pickup_location,
      "pickup_street_address": params[:pickup_street_address],
      "scheduled_at": params[:schedule_at],
      "pickup_contact_name": params[:pickup_contact_name] || @user.full_name,
      "pickup_contact_phone": params[:pickup_contact_phone] || @user.mobile,
      "destination_location": destination_location,
      "destination_street_address": destination_street_address,
      "destination_contact_name": destination_contact_name,
      "destination_contact_phone": destination_contact_phone
    }
  end

  def fetch_user
    @user ||= if @params["user_id"].present?
      User.find_by(id: @params["user_id"])
    else
      User.current_user
    end
  end

  def fetch_district_id
    @district_id ||= @params["district_id"].presence || @user.address.district_id
  end

end
