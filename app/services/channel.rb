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

    # users - can be array or single instance of user id or user object
    def private(users)
      [users].flatten.map do |user|
        user = user.id if user.is_a?(User)
        "user_#{user}"
      end
    end

    def user_channel?(channel_name)
      [channel_name].flatten.any? {|n| n.include?('user_')}
    end

  end
end
