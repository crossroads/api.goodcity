module Api
  module V1
    class DonorConditionsController < Api::V1::ApiController
      load_and_authorize_resource :donor_condition, parent: false
      skip_before_action :validate_token, only: :index

      resource_description do
        short 'Categorise the state a donation item is in. E.g. New / Used / Broken'
        formats ['json']
        error 401, "Unauthorized"
        error 404, "Not Found"
        error 422, "Validation Error"
        error 500, "Internal Server Error"
      end

      api :GET, '/v1/donor_conditions', "List all donor conditions."
      param :ids, Array, of: Integer, desc: "Filter by donor condition ids e.g. ids = [1,2,3,4]"
      def index
        render_objects_with_cache(@donor_conditions, params[:ids])
      end

      api :GET, '/v1/donor_conditions/1', "List a Donor-Condition"
      def show
        render json: @donor_condition, serializer: serializer
      end

      private

      def serializer
        Api::V1::DonorConditionSerializer
      end
    end
  end
end
