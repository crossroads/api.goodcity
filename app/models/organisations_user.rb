class OrganisationsUser < ActiveRecord::Base
  belongs_to :organisation
  belongs_to :user

  accepts_nested_attributes_for :user, allow_destroy: true, limit: 1

  after_create :send_welcome_msg, :create_user_role

  def self.create_or_update_existing_user_object(organisation_user)
    existing_user = User.find_by_mobile(organisation_user.user.mobile)
    unless existing_user.nil?
      return organisation_user if is_user_exists_in_organisation(existing_user, organisation_user)
      begin
        existing_user.update_attributes(first_name: organisation_user.user.first_name, last_name: organisation_user.user.last_name, email: organisation_user.user.email)
      rescue Exception => e
        return e
      end
      organisation_user.user_id = existing_user.id
      organisation_user
    else
      organisation_user
    end
  end

  def self.is_user_exists_in_organisation(existing_user, organisation_user)
    existing_user.organisations_users.exists? && existing_user.organisations_users.pluck(:organisation_id).include?(organisation_user.organisation_id)
  end

  private

  def send_welcome_msg
    TwilioService.new(user).send_welcome_msg
  end

  def create_user_role
    UserRole.create_user_role(user.id, Role.charity.id)
  end
end

