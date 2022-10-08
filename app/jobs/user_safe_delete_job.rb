class UserSafeDeleteJob < ActiveJob::Base

  def perform(user_id)
    user = User.find_by_id(user_id)
    if user
      Goodcity::UserSafeDelete.new(user).delete!
    end
  end

end
