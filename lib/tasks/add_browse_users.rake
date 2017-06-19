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
      user = create_new_user(f_name, l_name, mobile)
      add_user_to_organisation(user, o_name)
    else
      incorrect_command_prompt
    end
  end

  def incorrect_command_prompt
    puts "Incorrect command:\tEnter command in one of the following format:"
    puts "\t MOBILE=+85261111111 FIRST_NAME=Steve LAST_NAME=Jobs ORGANISATION=Apple cap production invoke:rake TASK=goodcity:add_user"
    puts "\t rake goodcity:add_user MOBILE=+85261111111 FIRST_NAME=Steve LAST_NAME=Jobs ORGANISATION=Apple"
  end

  def add_user_to_organisation(user, o_name)
    if(org = Organisation.find_by_name_en(o_name))
      organisation.users << user if(user.save!)
      puts "\t\t**User Added**"
    else
      puts "ORGANISATION not found!!!"
    end
  end

  def create_new_user(f_name, l_name, mobile)
    User.new(first_name: f_name, last_name: l_name, mobile: mobile)
  end
end
