class OrganisationsUserBuilder

  # :organisations_user: {
  #   :organisation_id,
  #   :position,
  #   :preferred_contact_number,
  #   user_attributes: {
  #     :first_name,
  #     :last_name,
  #     :mobile,
  #     :email
  #   }

  def initialize(params, app_name)
    @organisations_user = OrganisationsUser.find_by_id(params["id"]) if params["id"]
    @user = @organisations_user.user if @organisations_user
    @organisation_id = params["organisation_id"].presence.try(:to_i)
    @user_attributes = params["user_attributes"]
    @mobile = @user_attributes["mobile"].presence.try(:to_s)
    @email = @user_attributes["email"].presence
    @position = params["position"]
    @preferred_contact_number = params["preferred_contact_number"]
    @app_name = app_name
    fail_with_error(I18n.t("organisations_user_builder.organisation.blank")) unless @organisation_id
    fail_with_error(I18n.t("organisations_user_builder.user.mobile.blank")) unless @mobile
  end

  def build
    @user = build_user
    return fail_with_error(@user.errors) unless @user.valid?
    return fail_with_error(I18n.t("organisations_user_builder.organisation.not_found")) unless organisation
    if !user_belongs_to_organisation(@user)
      @organisations_user = @user.organisations_users.new(organisation_id: @organisation_id, position: @position, preferred_contact_number: @preferred_contact_number)
      TwilioService.new(@user).send_welcome_msg
      return fail_with_error(update_user["errors"]) if update_user && update_user["errors"]
      return_success.merge!("organisations_user" => @organisations_user)
    else
      return fail_with_error(I18n.t("organisations_user_builder.existing_user.present"))
    end
  end

  def build_user
    @user = User.where("email = (?) OR mobile = (?)", @email, @mobile).first_or_initialize(@user_attributes)
    assign_user_app_acessor
    @user.save
    @user
  end

  def assign_user_app_acessor
    @user.request_from_stock = (@app_name == STOCK_APP)
    @user.request_from_browse = (@app_name == BROWSE_APP)
  end

  def update
    assign_user_app_acessor
    return fail_with_error(update_user["errors"]) if update_user && update_user["errors"]
    @organisations_user.update(position: @position, preferred_contact_number: @preferred_contact_number)
    return_success.merge!("organisations_user" => @organisations_user.reload)
  end

  private

  def organisation
    @organisation ||= Organisation.find_by_id(@organisation_id)
  end

  def update_user
    @user.roles << charity_role unless @user.roles.include?(charity_role)
    if @user.update(@user_attributes)
      @user
    else
      fail_with_error(@user.errors.full_messages.join(" "))
    end
  end

  def user_belongs_to_organisation(user)
    user.organisation_ids.include?(@organisation_id)
  end

  def charity_role
    @charity_role ||= Role.charity
  end

  def fail_with_error(errors)
    errors = errors.full_messages.join(". ") if errors.respond_to?(:full_messages)
    {"result" => false, "errors" => errors}
  end

  def return_success
    {"result" => true}
  end
end
