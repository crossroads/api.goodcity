namespace :stockit do

  desc 'Load contact details from Stockit'
  task add_stockit_contacts: :environment do
    contacts_json = Stockit::ContactSync.index
    stockit_contacts = JSON.parse(contacts_json["contacts"]) || []
    bar = RakeProgressbar.new(stockit_contacts.size)
    stockit_contacts.each do |value|
      bar.inc
      contact = StockitContact.where(stockit_id: value["id"]).first_or_initialize
      contact.first_name = value["first_name"]
      contact.last_name = value["last_name"]
      contact.mobile_phone_number = value["mobile_phone_number"]
      contact.phone_number = value["phone_number"]
      contact.save
    end
    bar.finished
  end

end
