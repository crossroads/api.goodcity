# frozen_string_literal

module MessageService
  class Channels < Base
    attr_accessor :is_private

    def initialize(params)
      @is_private = params[:is_private]
      super(message: params[:message], app_name: params[:app_name])
    end

    def get_channel
      # This guy will give private or public channel
    end

    def related_users(channel)
      # This guy will give the members for the channel
    end
  end
end
