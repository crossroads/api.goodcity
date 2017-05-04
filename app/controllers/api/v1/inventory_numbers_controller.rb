module Api::V1
  class InventoryNumbersController < Api::V1::ApiController

    load_and_authorize_resource :inventory_number, parent: false

    resource_description do
      resource_description_errors
    end

    api :POST, "/v1/inventory_numbers", "Create inventory_number"
    def create
      render json: { inventory_number: generate_inventory_number }
    end

    api :PUT, "/v1/inventory_numbers", "Delete inventory_number"
    def remove_number
      fetch_inventory_number.try(:destroy)
      render json: {}
    end

    private

    def generate_inventory_number
      InventoryNumber.create(code: InventoryNumber.available_code).try(:code)
    end

    def fetch_inventory_number
      InventoryNumber.find_by(code: params[:code])
    end
  end
end
