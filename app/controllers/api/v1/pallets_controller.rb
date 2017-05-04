module Api::V1
  class PalletsController < Api::V1::ApiController

    load_and_authorize_resource :pallet, parent: false

    resource_description do
      short 'List and create pallets'
      resource_description_errors
    end

    def_param_group :pallet do
      param :pallet, Hash, required: true do
        param :pallet_number, String, desc: ""
        param :description, String, desc: "", allow_nil: true
        param :comments, String, desc: "", allow_nil: true
        param :stockit_id, String, desc: "", allow_nil: true
      end
    end

    api :POST, '/v1/pallets', "Create an pallet"
    param_group :pallet
    def create
      fetch_pallet.attributes = pallet_params
      if @pallet.save
        render json: {}, status: 201
      else
        render json: @pallet.errors.to_json, status: 422
      end
    end

    private

    def pallet_params
      params.require(:pallet).permit(:pallet_number, :description, :comments,
        :stockit_id)
    end

    def fetch_pallet
      @pallet = Pallet.find_by(stockit_id: params["pallet"]["stockit_id"]) || @pallet
    end

  end
end
