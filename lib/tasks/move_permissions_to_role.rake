#rake goodcity:move_permissions_to_role
namespace :goodcity do
  task move_permissions_to_role: :environment do
    Permission.find_each do |permission|
      Role.where(name: permission.name).first_or_create
    end
  end
end
