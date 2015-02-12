module Api::V1
  class DeliveriesController < Api::V1::ApiController

    load_and_authorize_resource :delivery, parent: false

    resource_description do
      short 'Get, create, and update deliveries.'
      formats ['json']
      error 401, "Unauthorized"
      error 404, "Not Found"
      error 422, "Validation Error"
      error 500, "Internal Server Error"
      description <<-EOS
        == Delivery relationships
        [link:/doc/deliveries_relationship.png]
        Generated using
          gem install railroady
          railroady -s app/models/delivery.rb,app/models/gogovan_order.rb,app/models/schedule.rb,app/models/address.rb,app/models/offer.rb,app/models/contact.rb -M | dot -Tpng > deliveries.png
      EOS
    end

    def_param_group :delivery do
      param :delivery,  Hash, required: true do
        param :offer_id, String, desc: "Id of offer to which delivery belongs."
        param :contact_id, String, allow_nil: true, desc: "Id of contact to which delivery belongs."
        param :schedule_id, String, allow_nil: true, desc: "Id of schedule to which delivery belongs."
        param :delivery_type, ["Alternate", "Drop Off", "Gogovan"], desc: "Delivery type."
        param :start, String, allow_nil: true, desc: "Not yet used"
        param :finish, String, allow_nil: true, desc: "Not yet used"
      end
    end

    api :POST, '/v1/deliveries', "Create a delivery"
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

    api :GET, '/v1/deliveries/1', "Get a delivery"
    def show
      render json: @delivery, serializer: serializer
    end

    api :PUT, '/v1/deliveries/1', "Update a delivery"
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
