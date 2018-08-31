class OrganisationsUserBuilder

  def initialize(organisations_user)
    @organisations_user = organisations_user
    @organisation_id = organisations_user.organisation_id
    @user = organisations_user.user
  end

  def build
    mobile = @user.mobile
    raise ValueError("No mobile provided") unless mobile.present?
    user = User.where(mobile: mobile).first_or_create(@user.attributes)
    if user && !user_belongs_to_organisation(user)
      @organisations_user.user = user
      if @organisations_user.save
        TwilioService.new(user).send_welcome_msg
        user.roles << charity_role unless user.roles.include?(charity_role)
      end
    end
    @organisations_user
  end

  private

  def user_belongs_to_organisation(user)
    user.organisation_ids.include?(@organisation_id)
  end

  def charity_role
    @charity_role ||= Role.charity
  end

end
