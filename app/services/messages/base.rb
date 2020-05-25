# frozen_string_literal: true

module Messages
  class Base
    attr_accessor :message, :messageable, :app_name, :current_user

    def initialize(params)
      @message = params[:message]
      @app_name = params[:app_name]
      @messageable = params[:messageable]
      @current_user = params[:current_user]
    end

    def owner?
      messageable.created_by_id == current_user.id
    end

    def add_subscriber(user_id, state)
      message.subscriptions.create(state: state,
                                   message_id: message.id,
                                   subscribable: messageable,
                                   user_id: user_id)
    end
  end
end
