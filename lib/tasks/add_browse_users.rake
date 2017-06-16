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
      puts "Incorrect command:\tEnter command in one of the following format:"
      puts "\t MOBILE=+85261111111 FIRST_NAME=Steve LAST_NAME=Jobs ORGANISATION=Apple cap production invoke:rake TASK=goodcity:add_user"
      puts "\t rake goodcity:add_user MOBILE=+85261111111 FIRST_NAME=Steve LAST_NAME=Jobs ORGANISATION=Apple"
    end
  end

  def create_user_for_organisation(f_name, l_name, mobile, o_name)
    if(org = Organisation.find_by_name_en(o_name))
      user = User.new(first_name: f_name, last_name: l_name, mobile: mobile)
      org.users << user if(user.save!)
      puts "\t\t**User Added**"
    else
      puts "ORGANISATION not found!!!"
    end
  end
end
