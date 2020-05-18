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

    def parse_user
      # This guy will parse the message
    end

  end
end
