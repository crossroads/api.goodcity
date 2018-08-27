module Api
  module V1
    class RequestsController < Api::V1::ApiController
      load_and_authorize_resource :request, parent: false

      resource_description do
        short 'List and create request'
        formats ['json']
        error 401, "Unauthorized"
        error 404, "Not Found"
        error 422, "Validation Error"
        error 500, "Internal Server Error"
      end

      def_param_group :request do
        param :request, Hash, required: true do
          param :quantity, String, desc: "requested quantity"
          param :description, String, desc: "request description", allow_nil: true
        end
      end

      api :POST, '/v1/requests', "Create request"
      param_group :request
      def create
        @request.created_by = User.current_user
        save_and_render_object_with_errors(@request)
      end

      api :PUT, "/v1/requests/1", "Update a request"
      def update
        @request.assign_attributes(request_params)
        save_and_render_object_with_errors(@request)
      end

      api :DELETE, "/v1/requests/1", "Delete request"
      def destroy
        @request.destroy
        render json: {}
      end

      private

      def serializer
        Api::V1::RequestSerializer
      end

      def request_params
        params.require(:request).permit(:quantity, :description, :package_type_id, :order_id)
      end
    end
  end
end
