module Api::V1
  class GogovanOrdersController < Api::V1::ApiController

    skip_before_action :validate_token, only: :driver_details
    skip_authorization_check only: :driver_details
    load_and_authorize_resource :gogovan_order, parent: false, except: [:driver_details]

    resource_description do
      short 'Gogovan: Calculate Price and Book Order'
      formats ['json']
      error 401, "Unauthorized"
      error 404, "Not Found"
      error 422, "Validation Error"
      error 500, "Internal Server Error"
    end

    api :POST, '/v1/gogovan_orders/calculate_price', "Calculate Price"
    param :pickupTime, String, desc: "Scheduled time for delivery"
    param :districtId, String, desc: "Id of the district", required: true
    param :needEnglish, ['true', 'false'], desc: "Speak English?"
    param :needCart, ['true', 'false'], desc: "Borrow Trolley(s)?"
    param :needCarry, ['true', 'false'], desc: "Porterage?"
    param :offerId, String, desc: "Id of the offer", required: true
    def calculate_price
      order_price = GogovanOrder.place_order(current_user, order_params)
      render json: order_price.to_json
    end

    def driver_details
      @offer = GogovanOrder.offer_by_ggv_uuid(params[:id])
      authorize!(:show_driver_details, @offer)
      render json: @offer, serializer: Api::V1::OfferSerializer, exclude_messages: true
    end

    private

    def order_params
      params.permit(["pickupTime", "districtId", "needEnglish", "needCart",
        "needCarry", "offerId", "gogovanOptionId"])
    end

    def serializer
      Api::V1::GogovanOrderSerializer
    end
  end
end
