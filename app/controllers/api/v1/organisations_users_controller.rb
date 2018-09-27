module Api
  module V1
    class OrganisationsUsersController < Api::V1::ApiController
      authorize_resource :organisations_user, parent: false

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
            param :title, String, desc: "Title of user"
          end
        end
      end

      api :POST, "/v1/organisations_user", "Create a package"
      param_group :organisations_user
      def create
        builder = OrganisationsUserBuilder.new(params['organisations_user'].to_hash).build
        if builder['result']
          save_and_render_object_with_errors(builder['organisations_user'])
        else
          render_error(builder['errors'])
        end
      end

      def update
        params['organisations_user']['id'] = params['id']
        builder = OrganisationsUserBuilder.new(params['organisations_user'].to_hash).update
        if builder['result']
          save_and_render_object_with_errors(builder['organisations_user'])
        else
          render_error(builder['errors'])
        end
      end

      private

      def organisations_user_params
        params.require(:organisations_user).permit(:organisation_id, :position, user_attributes: [:first_name,
          :last_name, :mobile, :email, :title])
      end

      def serializer
        Api::V1::OrganisationsUserSerializer
      end
    end
  end
end
