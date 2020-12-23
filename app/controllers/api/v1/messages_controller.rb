module Api
  module V1
    class MessagesController < Api::V1::ApiController
      load_and_authorize_resource :message, parent: false

      ALLOWED_SCOPES = %w[offer item order package].freeze

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
          param :recipient_id, String, desc: "Specific user id to subscribe the message to", allow_nil: true
        end
      end

      api :GET, "/v1/messages", "List all messages"
      param :ids, Array, of: Integer, desc: "Filter by message ids e.g. ids = [1,2,3,4]"
      param :offer_id, String, desc: "Return messages for offer id."
      param :is_private, %w[true false], desc: "Message Type e.g. [public, private]"
      param :item_id, String, desc: "Return messages for item id."
      param :order_id, String, desc: "Return messages for order id"
      param :package_id, String, desc: "Return messages for package id"
      param :state, String, desc: "Message state (unread|read) to filter on"
      def index
        @messages = apply_scope(@messages, params[:scope]) if params[:scope].present?
        @messages = apply_filters(@messages, params)
        @messages = @messages.with_state_for_user(current_user, params[:state].split(",")) if params[:state].present?
        paginate_and_render(@messages, serializer)
      end

      api :GET, "/v1/messages/1", "Get a message"
      def show
        render json: @message, serializer: serializer
      end

      api :POST, "/v1/messages", "Create an message"
      param_group :message
      def create
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

      api :GET, "/v1/messages/notifications", "List all notifications for current user"
      param :messageable_type, Array, desc: "Return messages for messageable_type"
      param :messageable_id, String, desc: "Return messages for messageable_id."
      param :is_private, ["true", "false"], desc: "Message Type e.g. [public, private]"
      param :state, String, desc: "Message state (unread|read) to filter on"
      def notifications
        @messages = apply_scope(@messages, params[:messageable_type]) if params[:messageable_type].present?
        @messages = apply_filters(@messages, params)
        @messages = @messages.joins(:subscriptions).where(subscriptions: {user_id: current_user.id})
        @messages = @messages.where(subscriptions: {state: params[:state]}) if params[:state].present?

        notification_ids = @messages
          .select("max(@messages.id) AS message_id")
          .page(page).per(per_page)
          .order('message_id DESC')
        
        if bool_param(:is_private, false)
          notification_ids = notification_ids.group("messageable_type, messageable_id, is_private")
        else
          notification_ids = notification_ids.group("messageable_type, messageable_id, is_private, sender_id, recipient_id")
        end

        @messages = @messages.where("messages.id IN (?)", notification_ids).order("messages.id DESC")

        render json: message_response(@messages, notification_serializer)
      end

      private

      def apply_filters(messages, options)
        messages = messages.unscoped.where(is_private: bool_param(:is_private, false)) if options[:is_private].present?
        messages = messages.where(messageable_id: options[:messageable_id]) if options[:messageable_id].present?

        %i[ids offer_id order_id item_id package_id].map do |f|
          messages = messages.send("filter_by_#{f}", options[f]) if options[f].present?
        end
        messages
      end

      def apply_scope(records, scope)
        scope = scope.split(',').flatten.compact.uniq
        scope = (scope & ALLOWED_SCOPES).map(&:camelize)
        records.where("messages.messageable_type IN (?)", scope)
      end

      def paginate_and_render(records, serializer)
        meta = {}
        if params[:page].present?
          records = records.page(page).per(per_page)
          meta = {
            total_pages: records.total_pages,
            total_count: records.total_count
          }
        end
        output = message_response(records, serializer)
        render json: { meta: meta }.merge(output)
      end

      def serializer
        Api::V1::MessageSerializer
      end

      def notification_serializer
        Api::V1::NotificationSerializer
      end

      def message_response(records, serializer)
        ActiveModel::ArraySerializer.new(records,
          each_serializer: serializer,
          root: "messages"
        ).as_json
      end

      def handle_backward_compatibility
        params['message']['order_id'] ||= params['message']['designation_id']
        %w[offer_id order_id item_id package_id].map do |param|
          if params['message'][param]
            params['message']['messageable_type'] = param.split('_')[0].camelize
            params['message']['messageable_id'] = params['message'][param]
          end
        end
      end

      def message_params
        # Manipulating the params for now to keep backward compatibility
        # as abilities needs to be handled
        handle_backward_compatibility
        params.require(:message).permit(
          :body, :is_private,
          :messageable_type,
          :messageable_id,
          :recipient_id
        )
      end
    end
  end
end
