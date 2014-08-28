module Api::V1
  class AddressesController < Api::V1::ApiController

    load_and_authorize_resource :address, parent: false

    def create
      @address.attributes = address_params
      if @address.save
        render json: @address, serializer: serializer, status: 201
      else
        render json: @address.errors.to_json, status: 500
      end
    end

    private

    def serializer
      Api::V1::AddressSerializer
    end

    def address_params
      params.require(:address).permit(:street, :flat, :building)
    end

  end
end
