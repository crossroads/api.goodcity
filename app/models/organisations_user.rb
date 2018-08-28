class OrganisationsUser < ActiveRecord::Base
  belongs_to :organisation
  belongs_to :user

  accepts_nested_attributes_for :user, allow_destroy: true, limit: 1

  after_create :send_welcome_msg, :create_user_role

  def create_or_update_existing_organisation_user
    existing_user = User.find_by_mobile(user.mobile)
    if existing_user && already_exist_in_same_organisation?(existing_user)
      existing_user.first_name = user.first_name
      existing_user.last_name = user.last_name
      existing_user.email = user.email
      existing_user.save
      self.user_id = existing_user.id
    end
    self
  end

  def already_exist_in_same_organisation?(existing_user)
    !existing_user.organisations.include?(organisation)
  end

  private

  def send_welcome_msg
    TwilioService.new(user).send_welcome_msg
  end

  def create_user_role
    UserRole.create_user_role(user.id, Role.charity.id)
  end
end

