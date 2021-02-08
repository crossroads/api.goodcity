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
        param :printer_id, Integer, desc: "Id of printer"
        param :user_id, Integer, desc: "Id of user"
        param :tag, String, desc: "A string identifier of the printer"
      end

      api :POST, '/v1/printers_users', "Create an printers_user"
      def create
        user_id, printer_id, tag = params["printers_users"].values_at('user_id', 'printer_id', 'tag')
        printer_user = PrintersUser
          .where(user_id: user_id, tag: tag)
          .first_or_initialize
        printer_user.printer_id = printer_id

        save_and_render_object(printer_user)
      end

      api :PUT, '/v1/printers_users/1', "Update printers_users"
      def update
        @printers_user.update(printers_user_params)
        render json: @printers_user, serializer: serializer
      end

      private

      def serializer
        Api::V1::PrintersUserSerializer
      end

      def printers_user_params
        params.require(:printers_users).permit(:printer_id, :user_id, :tag)
      end
    end
  end
end
