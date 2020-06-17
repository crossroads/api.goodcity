# frozen_string_literal: true

module Messages
  class Channels < Base
    attr_accessor :is_private

    def initialize(params)
      @is_private = ActiveRecord::Type::Boolean.new.type_cast_from_database(params[:is_private])
      super(params)
    end

    def related_users
      case app_name
      when DONOR_APP, ADMIN_APP
        admin_donor_mentions.uniq
      when STOCK_APP, BROWSE_APP
        stock_browse_mentions.uniq
      end
    end

    def admin_donor_mentions
      if is_private
        get_users_by_roles(['Supervisor'])
      else
        admin_donor_channel_users
      end
    end

    def admin_donor_channel_users
      users = get_users_by_roles(%w[Supervisor Reviewer]).uniq
      users << { id: messageable.created_by_id, name: messageable.created_by.full_name } unless owner?
      users
    end

    def stock_browse_mentions
      users = get_users_by_roles(['Order fulfilment', 'Order administrator'])
      users << { id: messageable.created_by_id, name: messageable.created_by.full_name } unless owner?
      users
    end

    private

    def user_roles
      User.where.not(users: { id: current_user.id, disabled: true })
          .joins(:user_roles)
          .joins(:roles)
    end

    def get_users_by_roles(roles)
      user_roles.where(roles: { name: roles }).uniq
                .map { |user| { id: user.id, name: user.full_name } }
    end
  end
end
