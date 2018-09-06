class OrganisationsUserBuilder

  # :organisations_user: {
  #   :organisation_id,
  #   :position,
  #   user_attributes: {
  #     :first_name,
  #     :last_name,
  #     :mobile,
  #     :email
  #   }

  def initialize(params)
    @organisation_id = params['organisation_id']
    @user_attributes = params['user_attributes']
    @mobile = @user_attributes['mobile']
    @position = @user_attributes['position']
    fail_with_error(I18n.t('organisations_user_builder.organisation.blank')) unless @organisation_id.present?
    fail_with_error(I18n.t('organisations_user_builder.user.mobile.blank')) unless @mobile.present?
  end

  def build
    user = User.where(mobile: @mobile).first_or_create(@user_attributes.to_hash)
    return fail_with_error(user.errors) unless user.valid?
    return fail_with_error(I18n.t('organisations_user_builder.organisation.not_found')) unless organisation
    if !user_belongs_to_organisation(user)
      organisations_user = OrganisationsUser.create!(organisation_id: @organisation_id, user_id: user.id, position: @position)
      TwilioService.new(user).send_welcome_msg
      user.roles << charity_role unless user.roles.include?(charity_role)
      return_success.merge!('organisations_user': organisations_user)
    else
      return fail_with_error(I18n.t('organisations_user_builder.existing_user.present'))
    end
  end

  private

  def organisation
    @organisation ||= Organisation.find_by_id(@organisation_id)
  end

  def user_belongs_to_organisation(user)
    user.organisation_ids.include?(@organisation_id.to_i)
  end

  def charity_role
    @charity_role ||= Role.charity
  end

  def fail_with_error(errors)
    errors = errors.full_messages.join('. ') if errors.respond_to?(:full_messages)
    { 'result' => false, 'errors' => errors }
  end

  def return_success
    { 'result': true }
  end

end
