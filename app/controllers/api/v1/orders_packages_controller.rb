module Api::V1
  class OrdersPackagesController < Api::V1::ApiController
    skip_authorization_check

    resource_description do
      formats ['json']
      error 401, "Unauthorized"
      error 404, "Not Found"
      error 422, "Validation Error"
      error 500, "Internal Server Error"
    end

    def_param_group :orders_packages do
      param :orders_packages, Hash, required: true do
        param :package_id, Integer, desc: "Id of package"
        param :order_id, Integer, desc: "Id of order"
        param :state, String, desc: "State of orders_package"
        param :quantity, Integer, desc: "Quantity of orders_package"
        param :sent_on, Date, desc: "date of dispatch"
      end
    end

    api :GET, '/v1/orders_packages', "List all orders_packages"
    def index
      return search if params['search_by_order_id'].present?
    end

    def search
      @orders_packages = OrdersPackage.find_records(params["search_by_order_id"])
      render json: @orders_packages, each_serializer: serializer
    end

    private

    def orders_packages_params
      params.require(:orders_packages).permit(:package_id, :order_id, :state, :quantity, :sent_on)
    end

    def serializer
      Api::V1::OrdersPackageSerializer
    end
  end
end
