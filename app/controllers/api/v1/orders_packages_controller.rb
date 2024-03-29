module Api
  module V1
    class OrdersPackagesController < Api::V1::ApiController
      load_and_authorize_resource :orders_package, parent: false

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
        # return all_orders_packages if params['all_orders_packages'].present?
        return orders_package_by_order_id if params['order_id'].present?
      end

      api :DELETE, '/v1/orders_package/1', "Delete an orders_package"
      def destroy
        @orders_package&.destroy
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

      # def all_orders_packages
      #   render json: @orders_packages, each_serializer: serializer
      # end

      def search
        @orders_packages = @orders_packages.get_records_associated_with_order_id(params["search_by_order_id"])
        render json: ActiveModel::ArraySerializer.new(@orders_packages, each_serializer: serializer).as_json
      end

      def show
        @orders_package = OrdersPackage.accessible_by(current_ability).with_eager_load.find(params[:id])
        render json: @orders_package, serializer: serializer
      end

      private

      def render_with_actions
        if @orders_package.errors.count.positive?
          render json: @orders_package.errors, status: 422
        else
          render json: serializer.new(
            OrdersPackage.where(id: @orders_package.id).includes([ { package: [ :locations, {package_type: [:location]}, :images] } ]).first,
            include_package: true,
            include_order: true,
            include_allowed_actions: true,
            include_orders_packages: true,
            include_packages_locations: true
          )
        end
      end

      # Returns the orders_packages associated with a particular package
      def search_by_package_id
        @orders_packages = @orders_packages.where(package_id: params["search_by_package_id"])
        @orders_packages = @orders_packages.includes(order: [:organisation, :country]).includes([:package]).includes([:updated_by])
        @orders_packages = apply_filters(@orders_packages).page(page).per(per_page)
        serialized_ops = ActiveModel::ArraySerializer.new(@orders_packages, each_serializer: serializer,
            root: 'orders_packages',
            include_order: true,
            include_allowed_actions: true,
            include_organisation: true,
            include_description_en: false,
            include_description_zh_tw: false,
            include_registration: false,
            include_website: false,
            include_organisation_type_id: false,
            include_district_id: false,
            include_country_id: false
          ).as_json
        render json: { meta: { total_pages: @orders_packages.total_pages, orders_packages_count: @orders_packages.size } }.merge(serialized_ops)
      end
      
      # Returns the orders_packages associated with a particular order
      def orders_package_by_order_id
        orders_packages = @orders_packages.where(order_id: params["order_id"])
        @orders_packages = apply_filters(orders_packages).page(page).per(per_page)
        render json: { meta: { total_pages: @orders_packages.total_pages, orders_packages_count: orders_packages.size } }.merge(serialized_orders_packages)
      end

      def apply_filters(orders_packages)
        orders_packages.search_and_filter({
          search_text: params['searchText'],
          state_names: array_param(:state),
          sort_column: params[:sort_column],
          is_desc: bool_param(:is_desc, false),
        })
      end

      def orders_packages_params
        params.require(:orders_packages).permit(:package_id, :order_id, :state, :quantity, :sent_on)
      end

      def serializer
        Api::V1::OrdersPackageSerializer
      end

      def serialized_orders_packages
        ActiveModel::ArraySerializer.new(
          @orders_packages,
          each_serializer: serializer,
          root: "orders_packages",
          include_package: true,
          include_orders_packages: true,
          include_packages_locations: true,
          include_allowed_actions: true
        ).as_json
      end
    end
  end
end
