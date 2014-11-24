module Api::V1
  class DeliveriesController < Api::V1::ApiController

    load_and_authorize_resource :delivery, parent: false

    def create
      @delivery = Delivery.find_by_offer_id(params[:offer_id]) || @delivery
      @delivery.attributes = delivery_params
      if @delivery.save
        render json: @delivery, serializer: serializer, status: 201
      else
        render json: @delivery.errors.to_json, status: 422
      end
    end

    def show
      render json: @delivery, serializer: serializer
    end

    def update
      @delivery.update_attributes(delivery_params)
      render json: @delivery, serializer: serializer
    end

    private

    def serializer
      Api::V1::DeliverySerializer
    end

    def delivery_params
      params.require(:delivery).permit(:start, :finish, :offer_id,
        :contact_id, :schedule_id, :delivery_type, :gogovan_order_id)
    end

  end
end
