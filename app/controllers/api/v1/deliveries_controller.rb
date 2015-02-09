module Api::V1
  class DeliveriesController < Api::V1::ApiController

    load_and_authorize_resource :delivery, parent: false

    resource_description do
      short 'Get, create, and update delivery.'
      description <<-EOS
        == Item states
        [link:/doc/delivery_state.png]
      EOS
      formats ['json']
      error 401, "Unauthorized"
      error 404, "Not Found"
      error 422, "Validation Error"
      error 500, "Internal Server Error"
    end

    def_param_group :delivery do
      param :delivery, Hash, required: true do
        param :start, Time.now
        param :finish, Time.now
        param :offer_id, String, allow_nil: true, desc: "Id of Offer to which delivery belongs."
        param :contact_id, String, allow_nil: true, desc: "Id of Offer to which delivery belongs."
        param :schedule_id, String, allow_nil: true, desc: "Id of Offer to which delivery belongs."
        param :delivery_type, [ "Alternate", "Drop Off", "Gogovan"], allow_nil: false, desc: "Delivery type."
      end
    end

    api :POST, '/v1/deliveries', "Create an delivery"
    param_group :delivery
    def create
      @delivery = Delivery.where(offer_id: params[:delivery][:offer_id]).last || @delivery
      @delivery.attributes = delivery_params
      if @delivery.save
        render json: @delivery, serializer: serializer, status: 201
      else
        render json: @delivery.errors.to_json, status: 422
      end
    end

    api :GET, '/v1/deliveries/1', "Get an delivery"
    param_group :delivery
    def show
      render json: @delivery, serializer: serializer
    end

    api :PUT, '/v1/deliveries/1', "Update an delivery"
    param_group :delivery
    def update
      if @delivery.update_attributes(delivery_params)
        render json: @delivery, serializer: serializer
      else
        render json: @delivery.errors.to_json, status: 422
      end
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
