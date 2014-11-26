module Api::V1
  class GogovanOrdersController < Api::V1::ApiController

    load_and_authorize_resource :gogovan_order, parent: false

    resource_description do
      short 'Gogovan: Calculate Price and Book Order'
      formats ['json']
      error 401, "Unauthorized"
      error 404, "Not Found"
      error 422, "Validation Error"
      error 500, "Internal Server Error"
    end

    api :POST, '/v1/gogovan_orders/calculate_price', "Calculate Price"
    param :pickupTime, String, desc: "Scheduled time for delivery", required: true
    param :districtId, String, desc: "Id of the district", required: true
    param :needEnglish, ['true', 'false'], desc: "Speak English?"
    param :needCart, ['true', 'false'], desc: "Borrow Trolley(s)?"
    param :needCarry, ['true', 'false'], desc: "Porterage?"
    def calculate_price
      order_price = GogovanOrder.place_order(current_user, order_params)
      render json: order_price.to_json
    end

    api :POST, '/v1/gogovan_orders/confirm_order', "Place Order"
    param :gogovan_order, Hash do
      param :name, String, desc: "Donor's name"
      param :mobile, String, desc: "Donor's mobile"
      param :pickup_time, String, desc: "Scheduled time for delivery", required: true
      param :district_id, Integer, desc: "Id of the district", required: true
      param :need_english, [true, false], desc: "Speak English?"
      param :need_cart, [true, false], desc: "Borrow Trolley(s)?"
      param :need_carry, [true, false], desc: "Porterage?"
    end
    def confirm_order
      attributes = params_hash(params["gogovan_order"])
      @gogovan_order = GogovanOrder.book_order(current_user, attributes)
      render json: @gogovan_order, serializer: serializer
    end

    private

    def order_params
      params.permit(["pickupTime", "districtId", "needEnglish", "needCart", "needCarry"])
    end

    # hash with keys in lower-camelcase form
    def params_hash(params)
      Hash[params.map{|(k,v)| [k.camelize(:lower),v]}]
    end

    def serializer
      Api::V1::GogovanOrderSerializer
    end
  end
end
