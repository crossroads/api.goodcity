module Api
  module V1
    class GoodcityRequestsController < Api::V1::ApiController
      load_and_authorize_resource :goodcity_request, parent: false

      resource_description do
        short 'List and create GoodcityRequest'
        formats ['json']
        error 401, "Unauthorized"
        error 404, "Not Found"
        error 422, "Validation Error"
        error 500, "Internal Server Error"
      end

      def_param_group :goodcity_request do
        param :goodcity_request, Hash, required: true do
          param :quantity, String, desc: "requested quantity"
          param :description, String, desc: "request description", allow_nil: true
          param :item_specifics, String, desc: "request item specifics", allow_nil: true
        end
      end

      api :POST, '/v1/goodcity_requests', "Create goodcity_request"
      param_group :goodcity_request
      def create
        @goodcity_request.created_by = User.current_user
        save_and_render_object_with_errors(@goodcity_request)
      end

      api :PUT, "/v1/goodcity_requests/1", "Update a goodcity_request"
      def update
        @goodcity_request.assign_attributes(goodcity_request_params)
        save_and_render_object_with_errors(@goodcity_request)
      end

      api :DELETE, "/v1/goodcity_requests/1", "Delete goodcity_request"
      def destroy
        @goodcity_request.destroy
        render json: {}
      end

      private

      def serializer
        Api::V1::GoodcityRequestSerializer
      end

      def goodcity_request_params
        params.require(:goodcity_request).permit(:quantity, :description, :package_type_id, :order_id, :item_specifics)
      end
    end
  end
end
