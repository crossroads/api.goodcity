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

    def users(users)
      users.pluck(:id).map {|id| "user_#{id}"}
    end

  end
end
