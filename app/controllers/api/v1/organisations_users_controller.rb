module Api::V1
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
        param :organisation_id, lambda { |val| [String, Fixnum].include? val.class }, desc: "Organisation of User", allow_nil: true
      end
    end

    api :POST, "/v1/organisations_user", "Create a package"
    # param_group :organisations_user
    def create
      @organisations_user.user.permission = Permission.charity
      save_and_render_object(@organisations_user)
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
