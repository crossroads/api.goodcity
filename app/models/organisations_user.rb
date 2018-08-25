class OrganisationsUser < ActiveRecord::Base
  belongs_to :organisation
  belongs_to :user

  accepts_nested_attributes_for :user, allow_destroy: true, limit: 1

  after_create :send_welcome_msg, :create_user_role

  def self.organisation_user?(org_user)
    user = User.find_by_mobile(org_user.user.mobile)
    unless user.nil?
      return org_user if user.organisations_users.exists? && user.organisations_users.pluck(:organisation_id).include?(org_user.organisation_id)
      user.update_attributes(first_name: org_user.user.first_name, last_name: org_user.user.last_name, email: org_user.user.email)
      org_user.user_id = user.id
      org_user
    else
      org_user
    end
  end

  private

  def send_welcome_msg
    TwilioService.new(user).send_welcome_msg
  end

  def create_user_role
    UserRole.create_user_role(user.id, Role.charity.id)
  end
end

