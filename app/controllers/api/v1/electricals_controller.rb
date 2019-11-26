module Api
  module V1
    class ElectricalsController < Api::V1::ApiController
      load_and_authorize_resource :electrical, parent: false

      resource_description do
        short "Create, update and show an Electrical."
        formats ["json"]
        error 401, "Unauthorized"
        error 404, "Not Found"
        error 422, "Validation Error"
        error 500, "Internal Server Error"
      end

      def_param_group :electrical do
        param :electrical, Hash do
          param :brand, String, desc: "name of the brand"
          param :model, String, desc: "model of the record"
          param :serial_number, String, desc: "serial number of the record"
          param :standard, String, desc: "size of the record"
          param :voltage, String, desc: "cpu of the record"
          param :frequency, String, desc: "ram of the record"
          param :power, String, desc: "hdd of the record"
          param :system_or_region, String, desc: "optical of the record"
          param :test_status, String, desc: "video of the record"
          param :tested_on, Date, desc: "sound of the record"
          param :updated_by_id, Integer, desc: "id of the user who updated the record"
        end
      end

      def index
        @electricals = @electricals.distinct_by_column(params["distinct"]) if params["distinct"]
        render json: @electricals, each_serializer: serializer
      end

      def show
        render json: @electrical, serializer: serializer, include_country: true
      end

      api :PUT, "/v1/electricals", "Create or Update an electrical"
      param_group :electrical
      def update
        @electrical.assign_attributes(electrical_params)
        update_and_render_object_with_errors(@electrical)
      end

      def destroy
        @electrical.destroy
        render json: {}
      end

      private

      def serializer
        Api::V1::ElectricalSerializer
      end

      def electrical_params
        attributes = %i[
          brand country_id frequency_id model power serial_number standard
          system_or_region test_status_id tested_on updated_by_id voltage_id
        ]
        params.require(:electrical).permit(attributes)
      end
    end
  end
end

