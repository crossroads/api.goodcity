# rake organisation:add_browse_users
namespace :organisation do
  task add_browse_users: :environment do
    add_users
  end

  def add_users
    loop do
      puts "Press Enter to add new user and other keys to quit"
      input = STDIN.gets.chomp
      break if (input != "")
      get_user_details
    end
  end

  def get_attribute(attr_name)
    print "Enter #{attr_name} \t: "
    STDIN.gets.chomp
  end

  def get_user_details
    f_name = get_attribute("FIRST_NAME")
    l_name = get_attribute("LAST_NAME")
    mobile = get_attribute("MOBILE_NUMBER(HK only)")
    o_name = get_attribute("ORGANISATION_NAME(must be same as in the DB)")
    create_user_for_organisation(f_name, l_name, mobile, o_name)
  end

  def create_user_for_organisation(f_name, l_name, mobile, o_name)
    if(org = Organisation.find_by_name_en(o_name))
      user = User.new(first_name: f_name, last_name: l_name, mobile: mobile)
      if(user.save)
        OrganisationsUser.create(organisation: org, user: user )
      else
        puts "Incorrect MOBILE_NUMBER"
      end
    else
      puts "ORGANISATION_NAME didn't match"
    end
    puts "\t\t**User Added**"
  end
end
