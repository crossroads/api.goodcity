module Api
  module V1
    class GoodcitySettingsController < Api::V1::ApiController
      load_and_authorize_resource :goodcity_setting, parent: false
      skip_before_action :validate_token, only: [:index]

      resource_description do
        short 'List, create and update GoodcitySetting'
        formats ['json']
        error 401, "Unauthorized"
        error 404, "Not Found"
        error 422, "Validation Error"
        error 500, "Internal Server Error"
      end

      def_param_group :goodcity_setting do
        param :goodcity_setting, Hash, required: true do
          param :key, String, desc: "the config key"
          param :value, String, desc: "the value"
          param :desc, String, desc: "a description of the configuration", allow_nil: true
        end
      end

      api :GET, '/v1/goodcity_settings', "List goodcity_settings"
      def index
        render json: @goodcity_settings, each_serializer: serializer, status: 200
      end

      api :POST, '/v1/goodcity_settings', "Create goodcity_setting"
      param_group :goodcity_setting
      def create
        save_and_render_object_with_errors(@goodcity_setting)
      end

      api :PUT, "/v1/goodcity_settings/1", "Update a goodcity_setting"
      def update
        @goodcity_setting.assign_attributes(goodcity_setting_params)
        save_and_render_object_with_errors(@goodcity_setting)
      end

      api :DELETE, "/v1/goodcity_settings/1", "Delete goodcity_setting"
      def destroy
        @goodcity_setting.destroy
        render json: {}
      end

      private

      def serializer
        Api::V1::GoodcitySettingSerializer
      end

      def goodcity_setting_params
        params.require(:goodcity_setting).permit(:key, :value, :desc)
      end
    end
  end
end
