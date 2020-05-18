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
        admin_donor_mentions
      when STOCK_APP, BROWSE_APP
        stock_browse_mentions
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
      users << messageable.created_by unless messageable.created_by_id == current_user.id
      users
    end

    def stock_browse_mentions
      users = stock_users
      users << messageable.created_by unless messageable.created_by_id == current_user.id
      users
    end

    private

    def for_supervisors_only?
      is_private && app_name == ADMIN_APP
    end

    def admin_supervisor_users
      User.joins(:user_roles)
          .joins(:roles)
          .where(roles: { name: ['Supervisor'] })
          .where.not(users: { id: current_user.id, disabled: true })
          .map { |user| [user.id, user.full_name] }
    end

    def supervisors_and_reviewers
      User.joins(:user_roles)
          .joins(:roles)
          .where(roles: {name: ['Supervisor', 'Reviewer']})
          .where.not(users: { id: current_user.id, disabled: true })
          .map { |user| [user.id, user.full_name] }
    end

    def stock_users
      User.joins(:user_roles)
          .joins(:roles)
          .where(roles: { name: ['Order fulfilment', 'Order administrator'] })
          .where.not(users: { id: current_user.id, disabled: true })
          .map { |user| [user.id, user.full_name] }
    end
  end
end
