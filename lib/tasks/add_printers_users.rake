

# rake goodcity:add_printers_users
namespace :goodcity do
  desc "Add Printers Users for printer_id in User table"
  task add_printers_users: :environment do
    Goodcity::Tasks::PrinterTasks.initialize_printers_users!
  end
end