namespace :goodcity do

  # rake goodcity:add_stockit_contacts
  desc 'Load contact details from stockit'
  task add_stockit_contacts: :environment do
    StockitContact.delete_all

    contacts_json = Stockit::ContactSync.index
    stockit_contacts = JSON.parse(contacts_json["contacts"])

    if stockit_contacts
      stockit_contacts.each do |value|
        contact = StockitContact.where(
          first_name: value["first_name"],
          last_name: value["last_name"],
          mobile_phone_number: value["mobile_phone_number"],
          phone_number: value["phone_number"],
          stockit_id: value["id"]
        ).first_or_create
      end
    end
  end
end
