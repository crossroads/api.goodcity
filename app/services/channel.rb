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

    def my_channel(user, is_admin_app)
      ["user_#{user.id}" + (is_admin_app ? "_admin" : "")]
    end

    def user_channel?(channel_name)
      [channel_name].flatten.any? {|n| n.include?('user_')}
    end

    def add_admin_app_prefix(channel_name)
      [channel_name].flatten.map {|c| user_channel?(c) ? "#{c}_admin" : c}
    end

  end
end
