class Channel
  class << self

    def reviewer
      ["reviewer"]
    end

    def supervisor
      ["supervisor"]
    end

    def staff
     [reviewer, supervisor].flatten
    end

    def user(user)
      ["user_#{user.id}"]
    end

    def user_id(user_id)
      ["user_#{user_id}"]
    end

    def users(users)
      users.pluck(:id).map {|id| "user_#{id}"}
    end

    def user_channel?(channel_name)
      channel_name.include?('user_')
    end

  end
end
