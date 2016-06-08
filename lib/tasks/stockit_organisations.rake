namespace :goodcity do

  # rake goodcity:add_stockit_organisations
  desc 'Load organisation details from stockit'
  task add_stockit_organisations: :environment do
    StockitOrganisation.delete_all

    organisations_json = Stockit::OrganisationSync.index
    stockit_organisations = JSON.parse(organisations_json["organisations"])

    if stockit_organisations
      stockit_organisations.each do |value|
        organisation = StockitOrganisation.where(
          name: value["name"],
          stockit_id: value["id"]
        ).first_or_create
      end
    end
  end
end
