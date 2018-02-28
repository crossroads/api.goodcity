class OrganisationsUser < ActiveRecord::Base
  belongs_to :organisation
  belongs_to :user

  accepts_nested_attributes_for :user, allow_destroy: true, limit: 1

  after_create :send_welcome_msg, :create_user_role

  private

  def send_welcome_msg
    TwilioService.new(user, organisation).send_welcome_msg
  end

  def create_user_role
    UserRole.create_user_role(user.id, Role.charity.id)
  end
end
