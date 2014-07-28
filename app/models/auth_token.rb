class AuthToken < ActiveRecord::Base
  belongs_to :user
  has_one_time_password

  def self.recent_auth_token
    order("id desc").first
  end
end
