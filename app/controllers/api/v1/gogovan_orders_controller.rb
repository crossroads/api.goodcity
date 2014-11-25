module Api::V1
  class GogovanOrdersController < Api::V1::ApiController

    load_and_authorize_resource :gogovan_order, parent: false

    def calculate_price
      order_price = GogovanOrder.place_order(current_user, order_params)
      render json: order_price.to_json
    end

    def confirm_order
      attributes = params_hash(params["gogovan_order"])
      @gogovan_order = GogovanOrder.book_order(current_user, attributes)
      render json: @gogovan_order, serializer: serializer
    end

    private

    def order_params
      params.permit(["pickupTime", "slot", "districtId", "territoryId", "needEnglish", "needCart", "needCarry"])
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
