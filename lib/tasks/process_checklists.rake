#rake goodcity:booking_types
namespace :goodcity do
  desc 'Initialize the different process checklists'
  task process_checklists: :environment do
    items_per_booking_type = YAML.load_file("#{Rails.root}/db/process_checklists.yml")
    items_per_booking_type.each do |bt_identifier, items|
      bt = BookingType.find_by(identifier: bt_identifier)
      items.each do |item|
        item[:booking_type_id] = bt.id
        ProcessChecklist.find_or_create_by(item)
      end
    end
  end
end
