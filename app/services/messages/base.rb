# frozen_string_literal: true

module MessageService
  class Base
    attr_accessor :message

    def initialize(parms)
      @message = params[:message]
      @app_name = params[:app_name]
    end

    def parse_user
      # This guy will parse the message
    end

  end
end
