module Api
  module V1
    class PrintersUsersController < Api::V1::ApiController
      load_and_authorize_resource :printers_user, parent: false

      resource_description do
        formats ['json']
        error 401, "Unauthorized"
        error 404, "Not Found"
        error 422, "Validation Error"
        error 500, "Internal Server Error"
      end

      def_param_group :printers_users do
        param :printers_users, Hash, required: true do
          param :package_id, Integer, desc: "Id of package"
          param :offer_id, Integer, desc: "Id of offer"
        end
      end

      api :POST, '/v1/printers_users', "Create an printers_user"
      def create
        save_and_render_object(@printers_user)
      end

      api :PUT, '/v1/holidays/1', "Update holiday"
      def update
        @printers_user.update_attributes(printers_users_params)
        render json: @printers_user, serializer: serializer
      end

      private

      def serializer
        Api::V1::PrintersUserSerializer
      end

      def printers_users_params
        params.require(:printers_users).permit(:printer_id, :user_id, :tag)
      end
    end
  end
end
