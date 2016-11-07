namespace :goodcity do

  # rake goodcity:add_stockit_countries
  desc 'Load countries from stockit'
  task add_stockit_countries: :environment do
    Country.delete_all

    countries_json = Stockit::CountrySync.index
    stockit_countries = JSON.parse(countries_json["countries"])

    if stockit_countries
      stockit_countries.each do |value|
        Country.where(
          name_en: value["name_en"],
          name_zh_tw: value["name_zh"],
          stockit_id: value["id"]
        ).first_or_create
      end
    end

  end
end
