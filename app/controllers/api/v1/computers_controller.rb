module Api
  module V1
    class ComputersController < Api::V1::ApiController
      load_and_authorize_resource :computer, parent: false

      resource_description do
        short "Create, update and show a computer."
        formats ["json"]
        error 401, "Unauthorized"
        error 404, "Not Found"
        error 422, "Validation Error"
        error 500, "Internal Server Error"
      end

      def_param_group :computer do
        param :computer, Hash do
          param :brand, String, desc: "name of the brand"
          param :model, String, desc: "model of the computer"
          param :serial_num, String, desc: "serial number of the computer"
          param :country_id, Integer, desc: "id of the country computer belongs to"
          param :size, String, desc: "size of the computer"
          param :cpu, String, desc: "cpu of the computer"
          param :ram, String, desc: "ram of the computer"
          param :hdd, String, desc: "hdd of the computer"
          param :optical, String, desc: "optical of the computer"
          param :video, String, desc: "video of the computer"
          param :sound, String, desc: "sound of the computer"
          param :lan, String, desc: "lan of the computer"
          param :wireless, String, desc: "wireless of the computer"
          param :usb, String, desc: "usb of the computer"
          param :comp_voltage, Integer, desc: "volage of the computer"
          param :os, String, desc: "operating system of the computer"
          param :os_serial_num, String, desc: "serial number of the OS of the computer"
          param :ms_office_serial_num, String, desc: "ms office serial num of the computer"
          param :mar_os_serial_num, String, desc: "mar os serial num of the computer"
          param :mar_ms_office_serial_num, String, desc: "mar ms office serial num of the computer"
          param :updated_by_id, Integer, desc: "id of the user who updated computer record"
        end
      end

      def index
        @computers = @computers.select('distinct on (computers.brand) computers.*')
        render json: @computers, each_serializer: serializer
      end

      api :PUT, "/v1/computers", "Create or Update a computer"
      param_group :computer
      def update
        @computer.assign_attributes(computer_params)
        if @computer.valid? and @computer.save
          render json: @computer, serializer: serializer
        else
          render_error(@computer.errors.full_messages.join(', '))
        end
      end

      private

      def serializer
        Api::V1::ComputerSerializer
      end

      def computer_params
        attributes = [:brand, :model, :serial_num, :country_id, :size,
          :cpu, :ram, :hdd, :optical, :video, :sound, :lan, :wireless,
          :usb, :comp_voltage, :os, :os_serial_num, :ms_office_serial_num,
          :mar_os_serial_num, :mar_ms_office_serial_num, :updated_by_id
        ]
        params.require(:computer).permit(attributes)
      end
    end
  end
end
