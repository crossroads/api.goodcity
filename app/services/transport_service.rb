class TransportService

  attr_accessor :provider_name, :params, :provider, :booking_id, :user, :district_id

  def initialize(options={})
    @params = options
    @provider_name = options && options[:provider]
    @provider ||= Object::const_get(provider_name)
    @booking_id = options && options[:booking_id]
    @transport_constants = Rails.application.secrets.transport

    fetch_user
    fetch_district_id
  end

  def quotation
    @provider.new(quotation_attributes).quotation
  end

  def book
    response = @provider.new(order_attributes).book
    if response[:error]
      response[:error]
    else
      store_order_details(response)
    end
  end

  def cancel
    response = @provider.cancel_order(booking_id)
    if response
      update_order_details({
        status: "cancelled",
        order_uuid: booking_id
      })
    end
  end

  def status
    response = @provider.transport_status(booking_id)
    if response
      update_order_details({
        status: response["status"],
        order_uuid: booking_id,
        metadata: response
      })
    end
  end

  private

  def store_order_details(response)
    TransportProviderOrder.create(
      transport_provider_id: TransportProvider.find_by(name: provider_name.upcase).try(:id),
      order_uuid: response["uuid"],
      status: response["status"],
      scheduled_at: response["pickup"]["schedule_at"],
      metadata: response,
      offer_id: @params[:offer_id]
    )
  end

  def update_order_details(response)
    order = TransportProviderOrder.find_by(order_uuid: response["order_uuid"])
    order.update_attributes(response)
  end

  def quotation_attributes
    {
      'vehicle_type': @params[:vehicle_type],
      "scheduled_at": @params[:scheduled_at],
      "pickup_location": pickup_location,
      "destination_location": @transport_constants[:crossroads_geolocation]
    }
  end

  def pickup_location
    pickup_district = District.find(@district_id)
    [pickup_district.latitude, pickup_district.longitude]
  end

  def order_attributes
    {
      'vehicle_type': @params[:vehicle_type],
      "pickup_location": pickup_location,
      "pickup_street_address": params[:pickup_street_address],
      "scheduled_at": params[:schedule_at],
      "pickup_contact_name": params[:pickup_contact_name] || @user.full_name,
      "pickup_contact_phone": params[:pickup_contact_phone] || @user.mobile,
      "destination_location": @transport_constants[:crossroads_geolocation],
      "destination_street_address": @transport_constants[:crossroads_street_address],
      "destination_contact_name": @transport_constants[:crossroads_contact_name],
      "destination_contact_phone": @transport_constants[:crossroads_contact_phone]
    }
  end

  def fetch_user
    @user ||= if @params[:user_id].present?
      User.find_by(id: @params[:user_id])
    else
      User.current_user
    end
  end

  def fetch_district_id
    @district_id ||= @params[:district_id].presence || @user.address.district_id
  end

end
