module Api
  module V1
    class BoxesController < Api::V1::ApiController
      load_and_authorize_resource :box, parent: false

      resource_description do
        short 'List and create boxes'
        formats ['json']
        error 401, "Unauthorized"
        error 404, "Not Found"
        error 422, "Validation Error"
        error 500, "Internal Server Error"
      end

      def_param_group :box do
        param :box, Hash, required: true do
          param :box_number, String, desc: ""
          param :description, String, desc: "", allow_nil: true
          param :comments, String, desc: "", allow_nil: true
          param :pallet_id, String, desc: "", allow_nil: true
        end
      end

      api :POST, '/v1/boxes', "Create an box"
      param_group :box
      def create
        @box.attributes = box_params
        if @box.save
          render json: {}, status: 201
        else
          render json: @box.errors, status: 422
        end
      end

      private

      def box_params
        params.require(:box).permit(
          :box_number, :description, :comments, :pallet_id
        )
      end
    end
  end
end
