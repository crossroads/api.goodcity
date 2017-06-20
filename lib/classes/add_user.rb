class AddUser
  def initialize(f_name, l_name, mobile, org_name)
    @user = User.new(first_name: f_name, last_name: l_name, mobile: mobile)
    @o_name = org_name
  end

  def add_user_to_organisation
    if((org = Organisation.find_by_name_en(@o_name)) && @user.save!)
      org.users << @user
    end
  end
end
