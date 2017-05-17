namespace :stockit do

  desc 'Load countries from Stockit'
  task add_stockit_countries: :environment do
    countries_json = Stockit::CountrySync.index
    stockit_countries = JSON.parse(countries_json["countries"]) || []
    stockit_countries.each do |value|
      country = Country.where(stockit_id: value["id"]).first_or_initialize
      country.name_en = value["name_en"]
      country.name_zh_tw = value["name_zh"]
      country.save
    end
  end

end
