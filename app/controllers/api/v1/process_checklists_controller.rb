module Api
  module V1
    class ProcessChecklistsController < Api::V1::ApiController
      load_and_authorize_resource :process_checklist, parent: false

      resource_description do
        short 'List Processing checklist items'
        formats ['json']
        error 401, "Unauthorized"
        error 404, "Not Found"
        error 422, "Validation Error"
        error 500, "Internal Server Error"
      end

      api :GET, '/v1/process_checklists', "List all processing checklists options."
      def index
        render json: @process_checklists, each_serializer: serializer
      end

      private

      def serializer
        Api::V1::ProcessChecklistSerializer
      end
    end
  end
end
