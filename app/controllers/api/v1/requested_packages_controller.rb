module Api
  module V1
    class RequestedPackagesController < Api::V1::ApiController
      load_and_authorize_resource :requested_package, parent: false

      resource_description do
        short 'Get requested packages.'
        formats ['json']
        error 401, "Unauthorized"
        error 404, "Not Found"
        error 422, "Validation Error"
        error 500, "Internal Server Error"
      end

      def_param_group :requested_package do
        param :requested_package, Hash, required: true do
          param :user_id, String
          param :package_id, String
          param :is_available, Boolean
          param :quantity, Integer
        end
      end

      def_param_group :checkout do
        param :order_id, String
        param :ignore_unavailable, :boolean
      end

      api :GET, '/v1/requested_packages', "List the user's requested packages"
      def index
        render json: @requested_packages, each_serializer: serializer
      end

      api :POST, '/v1/requested_packages', "Create a cart item"
      def create
        save_and_render_object_with_errors(@requested_package)
      end

      api :PUT, '/v1/requested_packages', "Update a cart item"
      def update
        @requested_package.assign_attributes(requested_package_params)
        if @requested_package.valid? && @requested_package.save
          render json: @requested_package, serializer: serializer
        else
          render_error(@requested_package.errors.full_messages.join("."))
        end
      end

      api :POST, '/v1/requested_packages/checkout', "Checkout and add all the packages to an order"
      param_group :checkout
      def checkout
        errors = CartCheckout
          .designate_requested_packages(@requested_packages, ignore_unavailable: bool_param("ignore_unavailable"))
          .to_order(checkout_order)

        if errors.any?
          render_error(errors.full_messages)
        else
          render json: checkout_order, serializer: Api::V1::OrderSerializer
        end
      end

      api :DELETE, '/v1/requested_packages/1', "Delete a cart item"
      def destroy
        @requested_package.destroy
        render json: {}
      end

      private

      def serializer
        Api::V1::RequestedPackageSerializer
      end

      def requested_package_params
        params.require(:requested_package).permit(
          :is_available,
          :user_id,
          :package_id,
          :quantity
        )
      end

      def checkout_order
        Order.find_by(id: params[:order_id]) if params[:order_id].present?
      end
    end
  end
end
