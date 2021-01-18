class OrganisationsUserBuilder

  # :organisations_user: {
  #   :organisation_id,
  #   :user_id,
  #   :position,
  #   :status,
  #   :preferred_contact_number,
  #   user_attributes: {
  #     :first_name,
  #     :last_name,
  #     :mobile,
  #     :email
  #   }

  # ------------------------
  # Entry points
  # ------------------------

  def self.create(organisations_user_params)
    OrganisationsUserBuilder.new(organisations_user_params.symbolize_keys).create!
  end

  def self.update(organisations_user_id, organisations_user_params)
    OrganisationsUserBuilder.new(organisations_user_params.symbolize_keys).update!(organisations_user_id)
  end

  # ------------------------
  # Implementation
  # ------------------------

  def initialize(organisation_id: nil, user_id: nil, user_attributes: nil, position: '', preferred_contact_number: '', status: '', change_author: User.current_user, force_replace: false)
    @change_author            = change_author
    @organisation_id          = organisation_id.to_i
    @position                 = position
    @status                   = status
    @preferred_contact_number = preferred_contact_number
    @user_attributes          = user_attributes&.symbolize_keys
    @user                     = strict_find!(User, user_id)
    @organisation             = strict_find!(Organisation, organisation_id)
    @force_replace            = force_replace
  end

  def create!
    @status = OrganisationsUser::Status::PENDING if @status.blank?

    assert_non_existing!
    assert_permissions!
    assert_no_conflicts!

    organisations_user = ActiveRecord::Base.transaction do
      apply_user_attributes!(@user, @user_attributes) if @user_attributes.present?
      OrganisationsUser.create!(create_params)
    end

    notify_user(@user)
    organisations_user
  end

  def update!(organisations_user_id)
    organisations_user = strict_find!(OrganisationsUser, organisations_user_id)

    assert_integrity!(organisations_user)
    assert_permissions!
    assert_no_conflicts!

    ActiveRecord::Base.transaction do
      apply_user_attributes!(@user, @user_attributes) if @user_attributes.present?

      organisations_user.position                   = @position unless @position.blank?
      organisations_user.status                     = @status unless @status.blank?
      organisations_user.preferred_contact_number   = @preferred_contact_number unless @preferred_contact_number.blank?

      organisations_user.save! if organisations_user.changed?
      organisations_user
    end
  end

  # ------------------------
  # Write methods
  # ------------------------

  def apply_user_attributes!(user, user_params)
    [:first_name, :last_name, :email, :mobile, :title].each do |field|
      user[field] = user_params[field] if user_params[field].present?
    end

    user.save! if user.changed?
  end

  # ------------------------
  # Helpers
  # ------------------------

  def create_params
    {
      user_id:                  @user.id,
      organisation_id:          @organisation_id,
      position:                 @position,
      status:                   @status,
      preferred_contact_number: @preferred_contact_number
    }
  end

  def notify_user(user)
    TwilioService.new(user).send_welcome_msg
  end

  def manager?(user)
    user&.api_user? || user&.has_permission?("can_manage_organisations_users")
  end

  # ------------------------
  # Error Management
  # ------------------------

  def strict_find!(model, id)
    record = id ? model.find_by(id: id) : nil
    raise Goodcity::BadOrMissingRecord.new(model) if record.blank?
    record
  end

  def assert_integrity!(organisations_user)
    raise Goodcity::ReadOnlyFieldError.new(:user_id).with_status(403)          if organisations_user.user_id != @user.id
    raise Goodcity::ReadOnlyFieldError.new(:organisation_id).with_status(403)  if organisations_user.organisation_id != @organisation_id
  end

  def assert_permissions!
    return if manager?(@change_author)

    raise Goodcity::AccessDeniedError if @change_author.id != @user.id                                      # A normal user can only create or modify his/her own records
    raise Goodcity::AccessDeniedError if @status.present? && @status != OrganisationsUser::INITIAL_STATUS   # A normal cannot set the status to anything but the inital "pending" status

    if @user_attributes.present?
      # Prevent users from modifying their existing verified email and mobile
      email, mobile = @user_attributes.values_at(:email, :mobile)

      raise Goodcity::ReadOnlyFieldError.new(:email) if email.present? && @user.is_email_verified && @user.email != email
      raise Goodcity::ReadOnlyFieldError.new(:mobile) if mobile.present? && @user.is_mobile_verified && @user.mobile != mobile
    end
  end

  def assert_non_existing!
    if OrganisationsUser.find_by(organisation_id: @organisation_id, user_id: @user.id).present?
      raise Goodcity::DuplicateRecordError.with_translation('organisations_user_builder.existing_user.present')
    end
  end

  def assert_no_conflicts!
    email, mobile = @user_attributes&.values_at(:email, :mobile)

    return if email.blank? && mobile.blank?

    conflicts = User
      .where.not(id: @user.id)
      .where("lower(email) = (?) OR mobile = (?)", email&.downcase, mobile)
      .count.positive?

    similar_user = User.where.not(id: @user.id)
                       .where('lower(email) = (?) OR mobile = (?)', email&.downcase, mobile)
    
    if similar_user.present?
      if @force_replace
        similar_user.refresh_auth_token!
        return similar_user.most_recent_token.otp_auth_key if @force_replace
      end
      raise Goodcity::AccessDeniedError.with_translation('organisations_user_builder.invalid.user') if conflicts
    end                   

  end
end
