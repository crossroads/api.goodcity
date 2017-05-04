module Api::V1
  class BoxesController < Api::V1::ApiController

    load_and_authorize_resource :box, parent: false

    resource_description do
      short 'List and create boxes'
      resource_description_errors
    end

    def_param_group :box do
      param :box, Hash, required: true do
        param :box_number, String, desc: ""
        param :description, String, desc: "", allow_nil: true
        param :comments, String, desc: "", allow_nil: true
        param :pallet_id, String, desc: "", allow_nil: true
        param :stockit_id, String, desc: "", allow_nil: true
      end
    end

    api :POST, '/v1/boxes', "Create an box"
    param_group :box
    def create
      assign_pallet
      fetch_box.attributes = box_params
      if @box.save
        render json: {}, status: 201
      else
        render json: @box.errors.to_json, status: 422
      end
    end

    private

    def box_params
      params.require(:box).permit(:box_number, :description, :comments,
        :pallet_id, :stockit_id)
    end

    def assign_pallet
      params["box"]["pallet_id"] = Pallet.find_by(stockit_id: params["box"]["pallet_id"]).try(:id)
    end

    def fetch_box
      @box = Box.find_by(stockit_id: params["box"]["stockit_id"]) || @box
    end

  end
end
