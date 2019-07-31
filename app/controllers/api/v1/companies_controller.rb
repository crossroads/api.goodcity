module Api
  module V1
    class CompaniesController < Api::V1::ApiController
      load_and_authorize_resource :company, parent: false

      resource_description do
        short "Create, update and show a company."
        formats ["json"]
        error 401, "Unauthorized"
        error 404, "Not Found"
        error 422, "Validation Error"
        error 500, "Internal Server Error"
      end

      def_param_group :company do
        param :company, Hash, required: true do
          param :name, String, desc: "name of the company"
          param :crm_id, Integer, desc: "CRM Id"
          param :created_by_id, Integer, desc: "Id of user who created company record"
        end
      end

      def index
        @companies = @companies.search({search_text: params["searchText"]})
          .page(page).per(per_page) if params["searchText"]
        render json: @companies, each_serializer: serializer
      end

      private

      def serializer
        Api::V1::CompaniesSerializer
      end
    end
  end
end
