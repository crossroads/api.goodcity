module Api
  module V1
    class OrdersController < Api::V1::ApiController
      load_and_authorize_resource :order, parent: false
      before_action :eager_load_designation, only: :show

      resource_description do
        short 'Retrieve a list of designations, information about stock items that have been designated to a group or person.'
        formats ['json']
        error 401, "Unauthorized"
        error 404, "Not Found"
        error 422, "Validation Error"
        error 500, "Internal Server Error"
      end

      def_param_group :order do
        param :order, Hash, required: true do
          param :status, String
          param :code, String
          param :created_at, String
          param :people_helped, :number
          param :detail_id, String, allow_nil: true
          param :stockit_id, String, desc: "stockit designation record id", allow_nil: true
          param :beneficiary_id, String, allow_nil: true
          param :address_id, String
          param :booking_type_id, String, desc: 'Booking type.(Online order or appointment)'
          param :staff_note, String, desc: 'Notes for internal use'
        end
      end

      api :POST, "/v1/orders", "Create or Update a order"
      param_group :order
      def create
        root = is_browse_app? ? "order" : "designation"
        if order_record.save
          render json: @order, serializer: serializer, root: root, status: 201
        else
          render json: @order.errors, status: 422
        end
      end

      api :GET, '/v1/orders', "List all orders"
      def index
        return my_orders if is_browse_app?
        return recent_designations if params['recently_used'].present?
        records = apply_filters(@orders)
          .search(params['searchText'], params['toDesignateItem'].presence)
          .page(params["page"]).per(params["per_page"] || DEFAULT_SEARCH_COUNT)
        orders = order_response(records)
        render json: {meta: {total_pages: records.total_pages, search: params['searchText']}}.merge(orders)
      end

      api :GET, '/v1/designations/1', "Get a order"
      def show
        root = is_browse_app? ? "order" : "designation"
        render json: serializer.new(@order,
          root: root,
          exclude_code_details: true,
          include_messages: bool_param(:include_messages, true),
          include_packages: bool_param(:include_packages, true),
          include_order: bool_param(:include_order, false),
          include_territory: true,
          include_images: true,
          include_allowed_actions: true,
          include_orders_packages: bool_param(:include_orders_packages, true)
        )
      end

      def transition
        event = params['transition'].to_sym
        @order.update_transition_and_reason(event, cancel_params) if @order.state_events.include?(event)
        render json: serializer.new(@order, include_allowed_actions: true)
      end

      api :PUT, '/v1/orders/1', "Update an order"
      param_group :order
      def update
        root = is_browse_app? ? "order" : "designation"
        @order.assign_attributes(order_params)
        # use valid? to ensure submit event errors get caught
        if @order.valid? and @order.save
          render json: @order, root: root, serializer: serializer
        else
          render json: { errors: @order.errors.full_messages } , status: 422
        end
      end

      def recent_designations
        records = Order.recently_used(User.current_user.id)
        render json: order_response(records)
      end

      def my_orders
        render json: @orders.my_orders.goodcity_orders, each_serializer: select_serializer,
          root: "orders", include_packages: false, browse_order: true
      end

      def destroy
        @order.destroy if @order.draft?
        render json: {}
      end

      def summary
        priority_and_non_priority_active_orders_count = Order.non_priority_active_orders_count.merge(
          Order.priority_active_orders_count
        )
        render json: priority_and_non_priority_active_orders_count
      end

      private

      def order_response(records)
        ActiveModel::ArraySerializer.new(records,
          each_serializer: select_serializer,
          root: "designations",
          include_packages: true,
          include_order: false,
          include_images: true,
          exclude_message_sender: bool_param(:exclude_message_sender, false),
          include_messages: bool_param(:include_messages, false)).as_json
      end

      def cancel_params
        {
          cancel_reason: params["cancel_reason"],
          cancellation_reason_id: params['cancellation_reason_id']
        }
      end

      def order_record
        if order_params[:stockit_id]
          @order = Order.accessible_by(current_ability).where(stockit_id: order_params[:stockit_id]).first_or_initialize
          @order.assign_attributes(order_params)
          @order.stockit_activity = stockit_activity
          @order.stockit_contact = stockit_contact
          @order.stockit_organisation = stockit_organisation
          @order.detail = stockit_local_order
        elsif is_browse_app?
          @order.assign_attributes(order_params)
          @order.created_by = current_user
          @order.detail_type = "GoodCity"
        end

        if order_params['beneficiary_attributes'] and @order.beneficiary.try(:created_by).nil?
          # New nested beneficiary
          @order.beneficiary.created_by = current_user
        end

        @order
      end

      def apply_filters(records)
        records.filter(
          states: array_param(:state),
          types: array_param(:type),
          priority: bool_param(:priority, false),
          with_notifications: params[:with_notifications],
          before: time_epoch_param(:before),
          after: time_epoch_param(:after)
        )
      end

      def order_params
        params.require(:order).permit(:district_id,
          :created_by_id, :stockit_id, :code, :status,
          :created_at, :organisation_id, :stockit_contact_id,
          :detail_id, :detail_type, :description,
          :state, :cancellation_reason, :state_event,
          :stockit_organisation_id, :stockit_activity_id,
          :people_helped, :beneficiary_id, :booking_type_id, :purpose_description,
          :address_id,:submitted_by_id, :staff_note,
          :exclude_message_sender, :include_messages,
          purpose_ids: [],
          beneficiary_attributes: beneficiary_attributes,
          address_attributes: address_attributes,
          orders_process_checklists_attributes: orders_process_checklists_attributes
        )
      end

      def address_attributes
        [:address_type, :district_id, :street, :flat, :building]
      end

      def beneficiary_attributes
        [:identity_type_id, :identity_number, :title, :first_name, :last_name, :phone_number]
      end

      def orders_process_checklists_attributes
        [:id, :order_id, :process_checklist_id, :_destroy]
      end

      def serializer
        Api::V1::OrderSerializer
      end

      def shallow_serializer
        Api::V1::OrderShallowSerializer
      end

      def select_serializer
        params[:shallow] == 'true' ? shallow_serializer : serializer
      end

      def stockit_activity
        StockitActivity.accessible_by(current_ability).find_by(stockit_id: params["order"]["stockit_activity_id"])
      end

      def stockit_contact
        StockitContact.accessible_by(current_ability).find_by(stockit_id: params["order"]["stockit_contact_id"])
      end

      def stockit_organisation
        StockitOrganisation.accessible_by(current_ability).find_by(stockit_id: params["order"]["stockit_organisation_id"])
      end

      def stockit_local_order
        StockitLocalOrder.accessible_by(current_ability).find_by(stockit_id: params["order"]["detail_id"])
      end

      def eager_load_designation
        @order = Order.accessible_by(current_ability).with_eager_load.find(params[:id])
      end
    end
  end
end
