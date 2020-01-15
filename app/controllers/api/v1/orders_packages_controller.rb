module Api
  module V1
    class OrdersPackagesController < Api::V1::ApiController
      load_and_authorize_resource :orders_package, parent: false
      before_action :eager_load_orders_package, only: :show

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
        return search_by_package_id if params['search_by_package_id'].present?
        # needs to be removed as it makes unwanted orders_packages request and makes the app slow
        return all_orders_packages if params['all_orders_packages'].present?
        return orders_package_by_order_id if params['order_id'].present?
      end

      api :DELETE, '/v1/orders_package/1', "Delete an orders_package"
      def destroy
        if @orders_package
          @orders_package.delete_orders_package
        end
        render json: {}
      end

      api :PUT, '/v1/orders_packages/:id/actions/:action_name', 'Executes an action'
      def exec_action
        begin
          @orders_package.exec_action(params[:action_name], params)
          render_with_actions
        rescue ArgumentError, StandardError => e
          render_error(e.to_s)
        end
      end

      def all_orders_packages
        render json: @orders_packages, each_serializer: serializer
      end

      def search_by_package_id
        @orders_packages = @orders_packages.get_designated_and_dispatched_packages(params["search_by_package_id"])
        render json: @orders_packages, each_serializer: serializer
      end

      def search
        @orders_packages = @orders_packages.get_records_associated_with_order_id(params["search_by_order_id"])
        render json: @orders_packages, each_serializer: serializer
      end

      def show
        render json: @orders_package, serializer: serializer
      end

      def eager_load_orders_package
        @orders_package = OrdersPackage.accessible_by(current_ability).with_eager_load.find(params[:id])
      end

      private

      def render_with_actions
        if @orders_package.errors.count.positive?
          render json: @orders_package.errors, status: 422
        else
          render json: serializer.new(
            @orders_package,
            include_package: true,
            include_allowed_actions: true,
            include_orders_packages: true
          )
        end
      end

      def orders_package_by_order_id
        records = @orders_packages.for_order(params["order_id"])
        orders_packages = records.page(params["page"]).per(params["per_page"])
        render json: ActiveModel::ArraySerializer.new(orders_packages,
          each_serializer: serializer,
          root: "orders_packages",
          include_package: true,
          include_orders_packages: true
        ).as_json
      end

      def orders_packages_params
        params.require(:orders_packages).permit(:package_id, :order_id, :state, :quantity, :sent_on)
      end

      def serializer
        Api::V1::OrdersPackageSerializer
      end
    end
  end
end
