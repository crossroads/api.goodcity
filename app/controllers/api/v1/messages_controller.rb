module Api
  module V1
    class MessagesController < Api::V1::ApiController
      load_and_authorize_resource :message, parent: false

      ALLOWED_SCOPES = %w[offer item order].freeze

      resource_description do
        short "List, show, create and mark_read a message."
        formats ["json"]
        error 401, "Unauthorized"
        error 404, "Not Found"
        error 422, "Validation Error"
        error 500, "Internal Server Error"
      end

      def_param_group :message do
        param :message, Hash, require: true do
          param :body, String, desc: "Message body", allow_nil: true
          param :sender, String, desc: "Message sent by"
          param :is_private, [true, false], desc: "Message Type e.g. [public, private]"
          param :offer_id, String, desc: "Offer for which message has been posted", allow_nil: true
          param :item_id, String, desc: "Item for which message has been posted", allow_nil: true
          param :state, String, desc: "Current User's Subscription State e.g. unread, read "
          param :order_id, String, desc: "Order id on which message is created", allow_nil: true
        end
      end

      api :GET, "/v1/messages", "List all messages"
      param :ids, Array, of: Integer, desc: "Filter by message ids e.g. ids = [1,2,3,4]"
      param :offer_id, String, desc: "Return messages for offer id."
      param :item_id, String, desc: "Return messages for item id."
      param :order_id, String, desc: "Return messages for order id"
      param :state, String, desc: "Message state (unread|read) to filter on"
      param :scope, String, desc: "The type of record associated to the messages (order/offer/item)"
      def index
        @messages = apply_scope(@messages, params[:scope]) if params[:scope].present?
        apply_filters
        paginate_and_render(@messages)
      end

      api :GET, "/v1/messages/1", "Get a message"
      def show
        render json: @message, serializer: serializer
      end

      api :POST, "/v1/messages", "Create an message"
      param_group :message
      def create
        @message.order_id = order_id
        @message.sender_id = current_user.id
        save_and_render_object(@message)
      end

      api :PUT, "/v1/messages/:id/mark_read", "Mark message as read"
      def mark_read
        @message.mark_read!(current_user.id, app_name)
        render json: @message, serializer: serializer
      end

      api :PUT, "/v1/messages/mark_all_read", "Mark all messages as read"
      def mark_all_read
        @subscriptions = Subscription.unread.for_user(User.current_user.id)
        if params[:scope].present?
          @subscriptions = apply_scope(@subscriptions.joins(:message), params[:scope])
        end
        @subscriptions.update_all state: 'read'
        render json: {}
      end

      private

      def apply_filters
        @messages = @messages.filter_by_ids(params[:ids].split(',')) if params[:ids].present?
        @messages = @messages.filter_by_offer(params[:offer_id].split(',')) if params[:offer_id].present?
        @messages = @messages.filter_by_order(params[:order_id].split(',')) if params[:order_id].present?
        @messages = @messages.filter_by_item(params[:item_id].split(',')) if params[:item_id].present?
        @messages = @messages.with_state_for_user(current_user, params[:state].split(',')) if params[:state].present?
      end

      def apply_scope(records, scope)
        return records unless ALLOWED_SCOPES.include? scope

        case scope
        when 'item'
          records.where('messages.item_id IS NOT NULL')
        when 'offer'
          records.where("messages.messageable_type = 'Offer'")
        when 'order'
          records.where("messages.messageable_type = 'Order'")
        end
      end

      def messageable
        return Order.find(order_id) if order_id.present?
        return Offer.find(offer_id) if offer_id.present?
        return Item.find(item_id) if item_id.present?
      end

      def paginate_and_render(records)
        meta = {}
        if params[:page].present?
          records = records.page(page).per(per_page)
          meta = {
            total_pages: records.total_pages,
            total_count: records.total_count
          }
        end
        output = message_response(records)
        render json: { meta: meta }.merge(output)
      end

      def item_id
        message_params[:item_id]
      end

      def order_id
        params[:message][:designation_id].presence || params[:message][:order_id].presence
      end

      def offer_id
        message_params[:offer_id]
      end

      def serializer
        Api::V1::MessageSerializer
      end

      def message_response(records)
        ActiveModel::ArraySerializer.new(records,
          each_serializer: serializer,
          root: "messages"
        ).as_json
      end

      def message_params
        params.require(:message).permit(
          :body, :is_private,
          :messageable_type,
          :messageable_id,
          :offer_id, :item_id, :order_id
        )
      end
    end
  end
end
