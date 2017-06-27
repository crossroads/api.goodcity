module Api::V1
  class InventoryNumbersController < Api::V1::ApiController

    load_and_authorize_resource :inventory_number, parent: false

    resource_description do
      formats ['json']
      error 401, "Unauthorized"
      error 404, "Not Found"
      error 422, "Validation Error"
      error 500, "Internal Server Error"
    end

    api :POST, "/v1/inventory_numbers", "Create inventory_number"
    def create
      inventory_number = InventoryNumber.create_with_next_code!
      render json: { inventory_number: inventory_number.code }
    end

    api :PUT, "/v1/inventory_numbers", "Delete inventory_number"
    def remove_number
      InventoryNumber.find_by(code: params[:code]).destroy
      render json: {}
    end

  end
end
