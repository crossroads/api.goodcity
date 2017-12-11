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

    def create

    end
  end
end
