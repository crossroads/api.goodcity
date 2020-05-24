# frozen_string_literal: true

module Messages
  class Channels < Base
    attr_accessor :is_private

    def initialize(params)
      @is_private = params[:is_private]
      super(params)
    end

    def related_users
      case app_name
      when DONOR_APP, ADMIN_APP
        Hash[admin_donor_mentions]
      when STOCK_APP, BROWSE_APP
        Hash[stock_browse_mentions]
      end
    end

    def admin_donor_mentions
      if for_supervisors_only?
        admin_supervisor_users
      else
        admin_donor_channel_users
      end
    end

    def admin_donor_channel_users
      users = supervisors_and_reviewers.uniq
      users << [messageable.created_by_id, messageable.created_by.full_name] unless owner?
      users
    end

    def stock_browse_mentions
      users = stock_users
      users << [messageable.created_by_id, messageable.created_by.full_name] unless owner?
      users
    end

    private

    def for_supervisors_only?
      is_private && app_name == ADMIN_APP
    end

    def user_roles
      User.where.not(users: { id: current_user.id, disabled: true })
          .joins(:user_roles)
          .joins(:roles)
    end

    def admin_supervisor_users
      user_roles.where(roles: { name: ['Supervisor'] })
                .map { |user| [user.id, user.full_name] }
    end

    def supervisors_and_reviewers
      user_roles.where(roles: { name: %w[Supervisor Reviewer] })
                .map { |user| [user.id, user.full_name] }
    end

    def stock_users
      user_roles
        .where(roles: { name: ['Order fulfilment', 'Order administrator'] })
        .map { |user| [user.id, user.full_name] }
    end
  end
end
