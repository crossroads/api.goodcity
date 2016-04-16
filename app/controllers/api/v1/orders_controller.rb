module Api::V1
  class OrdersController < Api::V1::ApiController

    api :GET, '/v1/orders', "List all orders"
    def index

      orders = Stockit::Designation
        .joins(:contact)
        .joins(:local_order)
        .joins(:country)
        .select(
          "designations.id, designations.code, designations.detail_type, countries.code AS country_code, designations.status, designations.created_at, designations.continuous,
          organisations.name,
          contacts.title, contacts.first_name, contacts.last_name, contacts.position, contacts.phone_number, contacts.mobile_phone_number, contacts.email,
          local_orders.client_name, local_orders.hkid_number"
        )
        .limit(100)

      render json: orders.to_json
    end

  end
end
