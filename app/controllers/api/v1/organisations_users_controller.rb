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

    api :POST, "/v1/organisations_user", "Create a package"
    # param_group :organisations_user
    def create
      if organisations_user_record
        render json: @organisations_user, serializer: serializer
      else
        render json: { errors: @organisations_user.errors.full_messages }.to_json , status: 422
      end
    end

    private

    def serializer
      Api::V1::OrganisationsUserSerializer
    end

    def organisations_user_record
      @organisations_user.user = User.build_new_user(params["oranisations_users"])
      @organisations_user.organisation_id = params["oranisations_users"]["organisation_id"]
      @organisations_user.save
    end
  end
end
