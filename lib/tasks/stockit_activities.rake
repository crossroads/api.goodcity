namespace :stockit do

  desc 'Load activity details from Stockit'
  task add_stockit_activities: :environment do
    activities_json = Stockit::ActivitySync.index
    stockit_activities = JSON.parse(activities_json["activities"])
    if stockit_activities
      stockit_activities.each do |value|
        StockitActivity.where(
          name: value["name"],
          stockit_id: value["id"]
        ).first_or_create
      end
    end
  end

end
