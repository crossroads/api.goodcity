class Channel

  # Channel definitions
  REVIEWER_CHANNEL = 'reviewer'
  SUPERVISOR_CHANNEL = 'supervisor'
  BROWSE_CHANNEL = 'browse'
  STOCK_CHANNEL = 'stock'
  ORDER_FULFILMENT_CHANNEL = 'order_fulfilment'
  STAFF_CHANNEL = [REVIEWER_CHANNEL, SUPERVISOR_CHANNEL]
  ORDER_CHANNEL = [REVIEWER_CHANNEL, SUPERVISOR_CHANNEL, BROWSE_CHANNEL]

  class << self

    # users - can be array or single instance of user id or user object
    # TODO replace with private channels for
    def private(users)
      [users].flatten.map{ |user| "user_#{user.is_a?(User) ? user.id : user}" }
    end
    # Returns the users private channel with app_name suffix
    # E.g. 'user_1' (donor app has no suffix)
    #   'user_1_admin', 'user_1_stock', 'user_1_browse'
    def private_channels_for(users, app_name = '')
      [users].flatten.compact.map do |user|
        u = user.is_a?(User) ? user.id : user
        if (app_name.blank? or app_name == DONOR_APP)
          "user_#{u}"
        else
          "user_#{u}_#{app_name}"
        end
      end.uniq
    end

    # Returns the channels a user should tune into given a particular app context
    # E.g. ['user_1_admin']
    #   ['user_1_browse', 'browse']
    def channels_for(user, app_name)
      channels = [private_channels_for(user, app_name)]
      channels << REVIEWER_CHANNEL if user.reviewer? and app_name == ADMIN_APP
      channels << SUPERVISOR_CHANNEL if user.supervisor? and app_name == ADMIN_APP
      channels << ORDER_FULFILMENT_CHANNEL if user.order_fulfilment? and app_name == STOCK_APP
      channels << BROWSE_CHANNEL if app_name == BROWSE_APP
      channels.flatten.compact.uniq
    end

    # TODO remove this once deleted from PushService
    # add the appropriate app_name suffix on the user channels when registering the device
    # e.g. user_1 becomes user_1_admin, group channels (don't start with 'user_') are unaffected
    # note that donor app channel is just user_1
    def add_app_name_suffix(channel_name, app_name)
      [channel_name].flatten.compact.map do |channel|
        if app_name != DONOR_APP && channel.starts_with?('user_') && !channel.ends_with?(app_name)
          "#{channel}_#{app_name}"
        else
          channel
        end
      end.reject(&:blank?)
    end

  end
end
