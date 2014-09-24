module Api::V1
  class MessagesController < Api::V1::ApiController

    load_and_authorize_resource :message, parent: false

    def index
      @messages = Message.current_user_messages(current_user.id)
      # @messages = @messages.with_eager_load # this maintains security
      @messages = @messages.where( id: params[:ids].split(",") ) if params[:ids].present?
      @messages = @messages.where(offer_id: params[:offer_id]) if params[:offer_id].present?
      @messages = @messages.where(item_id: params[:item_id]) if params[:item_id].present?
      # @messages = @messages.by_state(params[:state]) if params[:state]
      # @messages = Message.current_user_messages(current_user.id)

      render json: @messages, each_serializer: serializer
    end

    def show
      render json: @message, serializer: serializer
    end

    def create
      @message.attributes = message_params.merge(sender_id: current_user.id)
      @message = @message.save_with_subscriptions({state: params[:message][:state]})
      if @message
        render json: @message, serializer: serializer, status: 201
      else
        render json: @message.errors.to_json, status: 422
      end
    end

    private

    def serializer
      Api::V1::MessageSerializer
    end

    def message_params
      params.require(:message).permit(:body, :is_private, :recipient_id,
        :offer_id, :item_id)
    end
  end
end
