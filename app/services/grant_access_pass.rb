class GrantAccessPass
  attr_accessor :pass, :user, :access_key

  def initialize(access_key, user_id)
    @access_key = access_key
    @user = User.find_by(id: user_id)
    @user_id = user_id
    get_access_pass
  end

  def grant_access_by_pass
    assign_access_roles
    assign_printer(@pass.printer_id, "stock") if @pass.printer_id
  end

  def get_access_pass
    @pass = AccessPass.find_valid_pass(@access_key)
  end

  private

  def assign_access_roles
    @pass.roles.each do |role|
      @user.assign_role(@user_id, role.id, @pass.access_expires_at)
    end
  end

  def assign_printer(printer_id, tag)
    printer_user = @user.printers_users.where(tag: tag).first_or_initialize
    printer_user.printer_id = printer_id
    printer_user.save
  end
end
