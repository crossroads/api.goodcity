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

    def staff
     [reviewer, supervisor].flatten
    end

    # users - can be array or single instance of user id or user object
    def private(users)
      [users].flatten.map{ |user| "user_#{user.is_a?(User) ? user.id : user}" }
    end

    def user_channel?(channel_name)
      [channel_name].flatten.any? {|n| n.include?('user_')}
    end

    def add_admin_app_suffix(channel_name)
      [channel_name].flatten.map {|c| user_channel?(c) ? "#{c}_admin" : c}
    end

  end
end
