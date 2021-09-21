module Api
  module V1
    class AccessPassesController < Api::V1::ApiController
      load_and_authorize_resource :access_pass, parent: false

      resource_description do
        short 'Refresh and create access-passes'
        formats ['json']
        error 401, "Unauthorized"
        error 404, "Not Found"
        error 422, "Validation Error"
        error 500, "Internal Server Error"
      end

      def refresh
        @access_pass.refresh_pass
        render json: @access_pass, serializer: serializer
      end

      api :POST, '/v1/access_passes', "Create an access_pass"
      param :access_pass, Hash, required: true do
        param :role_ids, String, required: true, desc: "Array of Role Ids"
        param :access_expires_at, String, required: true, desc: "access_expires_at"
        param :printer_id, String, desc: "Printer Id", allow_nil: true
      end
      def create
        @access_pass.attributes = access_pass_params

        if @access_pass.save
          set_roles_for_access_pass(@access_pass, params[:access_pass][:role_ids])
          render json: @access_pass, serializer: serializer, status: 201
        else
          render_errors
        end
      end

      private

      def serializer
        Api::V1::AccessPassSerializer
      end

      def set_roles_for_access_pass(access_pass, role_ids)
        role_ids.split(",").each do |role_id|
          access_pass.access_pass_roles.find_or_create_by(
            access_pass: access_pass,
            role_id: role_id.to_i
          )
        end
      end

      def access_pass_params
        params.require(:access_pass).permit(
          :role_ids,
          :access_expires_at,
          :printer_id
        )
      end
    end
  end
end
