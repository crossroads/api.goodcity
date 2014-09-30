namespace :goodcity do

  # rake goodcity:add_reviewer phone=+85212345678
  desc 'Add Reviewer'
  task add_reviewer: :environment do
    user = User.find_by_mobile(ENV['phone'])
    reviewer_role = Permission.find_by_name('Reviewer')
    user.permissions << reviewer_role unless user.reviewer?
    puts "User has been given 'Reviewer' permission."
  end
end
