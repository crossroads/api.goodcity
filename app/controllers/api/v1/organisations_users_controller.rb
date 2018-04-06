module Api
  module V1
    class OrganisationsUsersController < Api::V1::ApiController
      load_and_authorize_resource :organisations_user, parent: false

      resource_description do
        short "Get Organisations Users."
        formats ["json"]
        error 401, "Unauthorized"
        error 404, "Not Found"
        error 500, "Internal Server Error"
      end

      def_param_group :organisations_user do
        param :organisations_user, Hash, required: true do
          param :organisation_id, String, desc: "Id of organisation to which user belongs"
          param :position, String, desc: "Position of user in organisation"
          param :user_attributes, Hash, required: true do
            param :first_name, String, desc: "First name of user"
            param :last_name, String, desc: "Family name of user"
            param :mobile, String, desc: "Mobile number of user"
            param :email, String, desc: "Email of user"
          end
        end
      end

      api :POST, "/v1/organisations_user", "Create a package"
      param_group :organisations_user
      def create
        save_and_render_object_with_errors(@organisations_user)
      end

      private

      def organisations_user_params
        params.require(:organisations_user).permit(:organisation_id, :position, user_attributes: [:first_name,
          :last_name, :mobile, :email])
      end

      def serializer
        Api::V1::OrganisationsUserSerializer
      end
    end
  end
end
