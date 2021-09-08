module Api
  module V1
    class AccessPassesController < Api::V1::ApiController

      load_and_authorize_resource :access_pass, parent: false

      def refresh
        @access_pass.refresh_pass
        render json: @access_pass, serializer: serializer
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
