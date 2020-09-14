module Api
  module V1
    class OrganisationsUsersController < Api::V1::ApiController
      authorize_resource :organisations_user, parent: false, except: [:user_status, :organisation_user]
      load_resource :organisations_user, only: [:show, :update]
      skip_authorization_check only: [:user_status, :organisation_user]

      resource_description do
        short "Get Organisations Users."
        formats ["json"]
        error 401, "Unauthorized"
        error 404, "Not Found"
        error 500, "Internal Server Error"
      end

      def_param_group :organisations_user do
        param :organisations_user, Hash, required: true do
          param :organisation_id, [Integer, String], required: true, desc: "Id of organisation to which user belongs"
          param :user_id, [Integer, String], required: true, desc: "Id of the user"
          param :position, String, desc: "Position of user in organisation"
          param :preferred_contact_number, String, desc: "Preferred contact number"
          param :status, String, desc: "Approval status"
          param :user_attributes, Hash, required: false do
            param :first_name, String, desc: "First name of user"
            param :last_name, String, desc: "Family name of user"
            param :mobile, String, desc: "Mobile number of user"
            param :email, String, desc: "Email of user"
            param :title, String, desc: "Title of user"
          end
        end
      end

      api :POST, "/v1/organisations_user", "Create an organisations_user"
      param_group :organisations_user
      def create
        record = OrganisationsUserBuilder.create(organisations_user_params.to_hash)
        render json: record, serializer: serializer, status: 201
      end

      api :POST, "/v1/organisations_user/:id", "Update an organisations_user"
      param_group :organisations_user
      def update
        record = OrganisationsUserBuilder.update(@organisations_user.id, organisations_user_params.to_hash)
        render json: record, serializer: serializer, status: 200
      end

      def show
        render json: @organisations_user, serializer: serializer
      end

      def user_status
        render json: { status: OrganisationsUser.all_status }, status: 200
      end

      private

      def organisations_user_params
        params.require(:organisations_user).permit(
          :organisation_id,
          :user_id,
          :position,
          :status,
          :preferred_contact_number,
          user_attributes: [
            :first_name,
            :last_name,
            :mobile,
            :email,
            :title
          ])
      end

      def serializer
        Api::V1::OrganisationsUserSerializer
      end
    end
  end
end
