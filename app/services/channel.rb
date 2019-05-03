class Channel

  # Channel definitions
  REVIEWER_CHANNEL = 'reviewer'.freeze
  SUPERVISOR_CHANNEL = 'supervisor'.freeze
  BROWSE_CHANNEL = 'browse'.freeze
  ORDER_FULFILMENT_CHANNEL = 'order_fulfilment'.freeze
  INVENTORY_CHANNEL = 'inventory'.freeze
  STAFF_CHANNEL = [REVIEWER_CHANNEL, SUPERVISOR_CHANNEL].freeze
  STOCK_CHANNEL = [INVENTORY_CHANNEL, ORDER_FULFILMENT_CHANNEL].freeze

  class << self

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
    # Also handles case when user is nil and they are on browse app
    def channels_for(user, app_name)
      channels = []
      if user.present?
        channels += [private_channels_for(user, app_name)]
        channels << REVIEWER_CHANNEL if user.reviewer? and app_name == ADMIN_APP
        channels << SUPERVISOR_CHANNEL if user.supervisor? and app_name == ADMIN_APP
        channels << ORDER_FULFILMENT_CHANNEL if user.order_fulfilment? and app_name == STOCK_APP
        channels << STOCK_CHANNEL if app_name == STOCK_APP
      end
      channels << BROWSE_CHANNEL if app_name == BROWSE_APP
      channels.flatten.compact.uniq
    end

  end
end
