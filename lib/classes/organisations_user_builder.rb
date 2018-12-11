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
    @organisations_user = OrganisationsUser.find_by_id(params['id']) if params['id']
    @user = @organisations_user.user if @organisations_user
    @organisation_id = params["organisation_id"].presence.try(:to_i)
    @user_attributes = params['user_attributes']
    @user_address_attributes = params['user_address_attributes']
    @district = District.find_by_id(@user_address_attributes['district_id'].presence&.to_i)
    @mobile = @user_attributes['mobile'].presence.try(:to_s)
    @position = params['position']
    fail_with_error(I18n.t('organisations_user_builder.organisation.blank')) unless @organisation_id
    fail_with_error(I18n.t('organisations_user_builder.user.mobile.blank')) unless @mobile
  end

  def build
    @user = User.where(mobile: @mobile).first_or_create(@user_attributes)
    return fail_with_error(@user.errors) unless @user.valid?
    return fail_with_error(I18n.t('organisations_user_builder.organisation.not_found')) unless organisation
    if !user_belongs_to_organisation(@user)
      @organisations_user = OrganisationsUser.create!(organisation_id: @organisation_id, user_id: @user.id, position: @position)
      TwilioService.new(@user).send_welcome_msg
      update_user
      return_success.merge!('organisations_user' => @organisations_user)
    else
      return fail_with_error(I18n.t('organisations_user_builder.existing_user.present'))
    end
  end

  def update
    update_user
    @organisations_user.update(position: @position)
    return_success.merge!('organisations_user' => @organisations_user.reload)
  end

  private

  def organisation
    @organisation ||= Organisation.find_by_id(@organisation_id)
  end

  def update_user
    update_user_address if @district
    @user.roles << charity_role unless @user.roles.include?(charity_role)
    @user.update(@user_attributes)
  end

  def update_user_address
    if @user.address
      @user.address.update(@user_address_attributes)
    else
      Address.create(addressable: @user, district_id: @user_address_attributes['district_id'])
    end
  end

  def user_belongs_to_organisation(user)
    user.organisation_ids.include?(@organisation_id)
  end

  def charity_role
    @charity_role ||= Role.charity
  end

  def fail_with_error(errors)
    errors = errors.full_messages.join('. ') if errors.respond_to?(:full_messages)
    { 'result' => false, 'errors' => errors }
  end

  def return_success
    { 'result' =>  true }
  end
end
