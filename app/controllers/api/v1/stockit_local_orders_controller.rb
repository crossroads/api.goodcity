module Api::V1
  class StockitLocalOrdersController < Api::V1::ApiController

    load_and_authorize_resource :stockit_local_order, parent: false

    resource_description do
      resource_description_errors
    end

    def_param_group :stockit_local_order do
      param :stockit_local_order, Hash, required: true do
        param :client_name, String
        param :hkid_number, String
        param :reference_number, String
        param :stockit_id, String, desc: "stockit local_order record id"
      end
    end

    api :POST, "/v1/stockit_local_orders", "Create or Update a stockit_local_order"
    param_group :stockit_local_order
    def create
      if stockit_local_order_record.save
        render json: @stockit_local_order, serializer: serializer, status: 201
      else
        render json: @stockit_local_order.errors.to_json, status: 422
      end
    end

    private

    def stockit_local_order_record
      @stockit_local_order = StockitLocalOrder.where(stockit_id: stockit_local_order_params[:stockit_id]).first_or_initialize
      @stockit_local_order.assign_attributes(stockit_local_order_params)
      @stockit_local_order
    end

    def stockit_local_order_params
      params.require(:stockit_local_order).permit(:stockit_id, :client_name,
        :hkid_number, :reference_number, :purpose_of_goods)
    end

    def serializer
      Api::V1::StockitLocalOrderSerializer
    end

  end
end
