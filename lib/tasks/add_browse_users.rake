# rake goodcity:add_user
namespace :goodcity do
  desc "Add new browse user 'MOBILE=+85261111111 FIRST_NAME=Steve LAST_NAME=Jobs ORGANISATION=Apple cap production invoke:rake TASK=goodcity:add_user'  "
  task add_user: :environment do
    get_user_details
  end

  def get_user_details
    f_name = ENV['FIRST_NAME']
    l_name = ENV['LAST_NAME']
    mobile = ENV['MOBILE']
    o_name = ENV['ORGANISATION']
    if (f_name && l_name && mobile && o_name)
      create_user_for_organisation(f_name, l_name, mobile, o_name)
    else

    end
  end

  def incorrect_command_prompt
    puts "Incorrect command:\tEnter command in one of the following format:"
    puts "\t MOBILE=+85261111111 FIRST_NAME=Steve LAST_NAME=Jobs ORGANISATION=Apple cap production invoke:rake TASK=goodcity:add_user"
    puts "\t rake goodcity:add_user MOBILE=+85261111111 FIRST_NAME=Steve LAST_NAME=Jobs ORGANISATION=Apple"
  end

  def add_user_to_organisation(f_name, l_name, mobile, o_name)
    if(org = Organisation.find_by_name_en(o_name))
      create_user(f_name, l_name, mobile, o_name, organisation)
      puts "\t\t**User Added**"
    else
      puts "ORGANISATION not found!!!"
    end
  end

  def create_user(f_name, l_name, mobile, o_name, organisation)
    user = User.new(first_name: f_name, last_name: l_name, mobile: mobile)
    organisation.users << user if(user.save!)
  end
end
