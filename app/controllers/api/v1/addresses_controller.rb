module Api
  module V1
    class AddressesController < Api::V1::ApiController
      load_and_authorize_resource :address, parent: false

      resource_description do
        short 'List and create addresses for Contacts and Users'
        formats ['json']
        error 401, "Unauthorized"
        error 404, "Not Found"
        error 422, "Validation Error"
        error 500, "Internal Server Error"
      end

      def_param_group :address do
        param :address, Hash, required: true do
          param :street, String, desc: "Street name", allow_nil: true
          param :flat, String, desc: "Flat name", allow_nil: true
          param :building, String, desc: "Building name", allow_nil: true
          param :district_id, String, desc: "Hong Kong district"
          param :address_type, String, desc: "Type of address, usually 'Collection' or 'Profile'"
          param :addressable_type, String, desc: "Object the address belongs to: 'Contact' or 'User' (Polymorphic)"
          param :addressable_id, String, desc: "Object id of the associated polymorphic record. Use contact_id or user_id"
          param :notes, String, desc: "Delivery instructions and other notes"
        end
      end

      api :POST, '/v1/addresses', "Create an address"
      param_group :address
      def create
        save_and_render_object(@address)
      end

      api :GET, '/v1/address/1', "Show an address"
      def show
        render json: @address, serializer: serializer
      end

      private

      def serializer
        Api::V1::AddressSerializer
      end

      def address_params
        params.require(:address).permit(:street, :flat, :building, :notes,
          :district_id, :address_type, :addressable_id, :addressable_type)
      end
    end
  end
end
