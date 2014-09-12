module Api::V1
  class MessagesController < Api::V1::ApiController

    load_and_authorize_resource :message, parent: false

    def index
      @messages = @messages.find( params[:ids].split(",") ) if params[:ids].present?
      @messages = @messages.where(offer_id: params[:offer_id]) if params[:offer_id].present?
      render json: @messages, each_serializer: serializer
    end

    def show
      render json: @message, serializer: serializer
    end

    def create
      @message.attributes = message_params.merge(sender_id: current_user.id)
      if @message.save
        render json: @message, serializer: serializer, status: 201
      else
        render json: @message.errors.to_json, status: 500
      end
    end

    private

    def serializer
      Api::V1::MessageSerializer
    end

    def message_params
      params.require(:message).permit(:body, :is_private, :sender_id, :recipient_id, :offer_id, :item_id)
    end

  end
end
