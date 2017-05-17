namespace :stockit do

  desc 'Load organisation details from stockit'
  task add_stockit_organisations: :environment do
    organisations_json = Stockit::OrganisationSync.index
    stockit_organisations = JSON.parse(organisations_json["organisations"]) || []
    stockit_organisations.each do |value|
      org = StockitOrganisation.where(stockit_id: value["id"]).first_or_initialize
      org.name = value["name"]
      org.save
    end
  end

end
