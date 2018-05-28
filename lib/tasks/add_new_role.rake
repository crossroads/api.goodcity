namespace :goodcity do
  desc 'Add new roles'
  task add_new_roles: :environment do
    ROLES = ["Charity", "Order fulfilment"].freeze

    ROLES.each do |role|
      Permission.where(name: role).first_or_create
    end
  end
end
