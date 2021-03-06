module Api
  module V1
    class StockitActivitiesController < Api::V1::ApiController
      load_and_authorize_resource :stockit_activity, parent: false

      resource_description do
        formats ['json']
        error 401, "Unauthorized"
        error 404, "Not Found"
        error 422, "Validation Error"
        error 500, "Internal Server Error"
      end

      def_param_group :stockit_activity do
        param :stockit_activity, Hash, required: true do
          param :name, String, desc: "Name of Activity"
        end
      end

      api :POST, "/v1/stockit_acitivites", "Create or Update a stockit_activity"
      param_group :stockit_activity
      def create
        if stockit_activity_record.save
          render json: {}, status: 201
        else
          render json: @stockit_activity.errors, status: 422
        end
      end

      private

      def stockit_activity_record
        @stockit_activity = StockitActivity.new
        @stockit_activity.assign_attributes(stockit_activity_params)
        @stockit_activity
      end

      def stockit_activity_params
        params.require(:stockit_activity).permit(:name)
      end
    end
  end
end
