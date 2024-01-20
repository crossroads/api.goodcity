class UserSafeDeleteJob < ActiveJob::Base

  def perform(user_id)
    user = User.find_by_id(user_id)
    return unless user

    user_safe_delete = Goodcity::UserSafeDelete.new(user)
    if user_safe_delete.can_delete?
      user_safe_delete.delete!
    else
      reason = user_safe_delete.can_delete[:reason]
      ActionMailer::Base.mail(
        from: ENV['EMAIL_FROM'],
        to: ENV['EMAIL_FROM'],
        subject: "GoodCity.HK failed user deletion",
        body: "Please assist GoodCity.HK user ##{user.id}. Their deletion request failed:\n\n#{reason}"
      ).deliver
    end
  end

end
