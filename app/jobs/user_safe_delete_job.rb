class UserSafeDeleteJob < ActiveJob::Base

  def perform(user_id)
    user = User.find_by_id(user_id)
    return unless user
    
    user_safe_delete = Goodcity::UserSafeDelete.new(user)
    if user_safe_delete.can_delete?
      user_safe_delete.delete!
    else
      # TODO notify queue email to note that deletion failed
    end
  end

end
