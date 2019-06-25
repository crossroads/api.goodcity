module Api
  module V1
    class CartItemsController < Api::V1::ApiController
      load_and_authorize_resource :cart_item, parent: false

      resource_description do
        short 'Get cart items.'
        formats ['json']
        error 401, "Unauthorized"
        error 404, "Not Found"
        error 422, "Validation Error"
        error 500, "Internal Server Error"
      end

      def_param_group :cart_item do
        param :cart_item, Hash, required: true do
          param :user_id, String
          param :package_id, String
          param :is_available, Boolean
        end
      end

      def_param_group :checkout do
        param :order_id, String
        param :ignore_unavailable, :boolean
      end

      api :GET, '/v1/cart_items', "List the user's cart items"
      def index
        render json: @cart_items, each_serializer: serializer
      end

      api :POST, '/v1/cart_items', "Create a cart item"
      def create
        save_and_render_object_with_errors(@cart_item)
      end

      api :POST, '/v1/cart_items/checkout', "Checkout and add all the packages to an order"
      param_group :checkout
      def checkout
        errors = CartCheckout
          .designate_cart_items(@cart_items, ignore_unavailable: bool_param("ignore_unavailable"))
          .to_order(checkout_order)

        if errors.any?
          render_error(errors.full_messages)
        else
          render json: checkout_order, serializer: Api::V1::OrderSerializer
        end
      end

      api :DELETE, '/v1/cart_items/1', "Delete a cart item"
      def destroy
        @cart_item.destroy
        render json: {}
      end

      private

      def serializer
        Api::V1::CartItemSerializer
      end

      def cart_item_params
        params.require(:cart_item).permit(
          :is_available,
          :user_id,
          :package_id
        )
      end

      def checkout_order
        Order.find_by(params[:order_id]) if params[:order_id].present?
      end

      def bool_param(key)
        return false if params[key].nil?
        params[key].to_s == "true"
      end
    end
  end
end
