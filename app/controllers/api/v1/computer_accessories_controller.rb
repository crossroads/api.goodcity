module Api
  module V1
    class ComputerAccessoriesController < Api::V1::ApiController
      load_and_authorize_resource :computer_accessory, parent: false

      resource_description do
        short "Create, update and show a computer_accessory."
        formats ["json"]
        error 401, "Unauthorized"
        error 404, "Not Found"
        error 422, "Validation Error"
        error 500, "Internal Server Error"
      end

      def_param_group :computer_accessory do
        param :computer_accessory, Hash do
          param :brand, String, desc: "name of the brand"
          param :model, String, desc: "model of the record"
          param :serial_num, String, desc: "serial number of the record"
          param :size, String, desc: "size of the record"
          param :interface, String, desc: "interface of the record"
          param :comp_voltage, Integer, desc: "comp_voltage of the record"
          param :comp_test_status, String, desc: "comp_test_status of the record"
          param :updated_by_id, Integer, desc: "updated_by_id of the record"
        end
      end

      def index
        @computer_accessories = @computer_accessories.distinct_by_column(params["distinct"]) if params["distinct"]
        render json: @computer_accessories, each_serializer: serializer
      end

      def show
        render json: @computer_accessory, serializer: serializer, include_country: true
      end

      api :PUT, "/v1/computers", "Create or Update a computer"
      param_group :computer_accessory
      def update
        @computer_accessory.assign_attributes(computer_accessory_params)
        update_and_render_object_with_errors(@computer_accessory)
      end

      private

      def serializer
        Api::V1::ComputerAccessorySerializer
      end


      def computer_accessory_params
        attributes = [:brand, :comp_test_status, :comp_voltage, :country_id, :interface,
          :model, :serial_num, :size, :updated_by_id]
        params.require(:computer_accessory).permit(attributes)
      end
    end
  end
end
