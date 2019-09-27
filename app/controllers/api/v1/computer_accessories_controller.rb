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
          param :serial_number, String, desc: "serial number of the record"
          param :country_id, Integer, desc: "id of the country record belongs to"
          param :size, String, desc: "size of the record"
          param :interface, String, desc: "interface of the record"
          param :comp_voltage, Integer, desc: "comp_voltage of the record"
          param :comp_test_status, String, desc: "comp_test_status of the record"
          param :updated_by_id, Integer, desc: "updated_by_id of the record"
        end
      end

      api :POST, "/v1/computer_accessorys", "Create or Update a stockit_local_order"
      param_group :computer_accessory
      def create
        save_and_render_object_with_errors(@computer_accessory)
      end

      private

      def computer_accessory_params
        attributes = [:brand, :model, :serial_number, :country_id, :size,
          :interface, :comp_voltage, :comp_test_status, :updated_by_id
        ]
        params.require(:computer_accessory).permit(attributes)
      end
    end
  end
end
