class OrganisationsUser < ActiveRecord::Base
  belongs_to :organisation
  belongs_to :user

  accepts_nested_attributes_for :user, allow_destroy: true, limit: 1

  after_create :send_welcome_msg

  private

  def send_welcome_msg
    TwilioService.new(user, organisation).send_welcome_msg
  end
end
