class Channel
  class << self

    def reviewer
      ["reviewer"]
    end

    def supervisor
      ["supervisor"]
    end

    def browse
      ["browse"]
    end

    def order_fulfilment
      ["order_fulfilment"]
    end

    def staff
     [reviewer, supervisor].flatten
    end

    def goodcity_order_channel
      [order_fulfilment].flatten
    end

    def order_channel
      [reviewer, supervisor, browse].flatten
    end

    # users - can be array or single instance of user id or user object
    def private(users)
      [users].flatten.map{ |user| "user_#{user.is_a?(User) ? user.id : user}" }
    end

    def user_channel?(channel_name)
      [channel_name].flatten.any? {|n| n.include?('user_')}
    end

    # Gets the channels for a user and ensures the correct app_name context
    # E.g. user_1_admin, user_1_browse
    def channels_for_user_with_app_context(current_user, app_name)
      channels = current_user.channels
      channels = Channel.add_app_name_suffix(channels, app_name)
      channels
    end

    # TODO deprecate this method
    def add_admin_app_suffix(channel_name)
      [channel_name].flatten.map {|c| user_channel?(c) ? "#{c}_admin" : c}
    end

    # add the appropriate app_name suffix on the user channels when registering the device
    # e.g. user_1 becomes user_1_admin, group channels (don't start with 'user_') are unaffected
    # note that donor app channel is just user_1
    def add_app_name_suffix(channel_name, app_name)
      [channel_name].flatten.compact.map do |channel|
        if app_name != DONOR_APP && user_channel?(channel)
          "#{channel}_#{app_name}"
        else
          channel
        end
      end.reject(&:blank?)
    end

  end
end
