module Api
  module V1
    class OrdersProcessChecklistsController < Api::V1::ApiController
      authorize_resource :orders_process_checklist, parent: false
      load_resource :orders_process_checklist, only: [:show]

      resource_description do
        short "Get orders_process_checklists."
        formats ["json"]
        error 401, "Unauthorized"
        error 404, "Not Found"
        error 500, "Internal Server Error"
      end

      def index
        @orders_process_checklists = OrdersProcessChecklist.by_order(params[:order_id])
        render json: @orders_process_checklists, each_serializer: serializer
      end

      private

      def serializer
        Api::V1::OrdersProcessChecklistsSerializer
      end
    end
  end
end
