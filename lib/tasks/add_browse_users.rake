require 'classes/add_user'

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
    if(all_names_exists?(f_name, l_name, mobile, o_name))
      save_user(f_name, l_name, mobile, o_name)
    else
      print_message
    end
  end

  def save_user(f_name, l_name, mobile, o_name)
    user = AddUser.new(f_name, l_name, mobile, o_name)
    if(user.add_user_to_organisation)
      puts "\t\t**User Added**"
    else
      puts "ORGANISATION not found!!!"
    end
  end

  def all_names_exists?(f_name, l_name, mobile, o_name)
    f_name && l_name && mobile && o_name
  end

  def print_message
    puts "Incorrect command:\tEnter command in one of the following format:"
    puts "\t MOBILE=+85261111111 FIRST_NAME=Steve LAST_NAME=Jobs ORGANISATION=Apple cap production invoke:rake TASK=goodcity:add_user"
    puts "\t rake goodcity:add_user MOBILE=+85261111111 FIRST_NAME=Steve LAST_NAME=Jobs ORGANISATION=Apple"
  end
end
