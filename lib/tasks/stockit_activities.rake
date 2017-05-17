namespace :stockit do

  desc 'Load activity details from Stockit'
  task add_stockit_activities: :environment do
    activities_json = Stockit::ActivitySync.index
    stockit_activities = JSON.parse(activities_json["activities"]) || []
    stockit_activities.each do |value|
      activity = StockitActivity.where(stockit_id: value["id"]).first_or_initialize
      activity.name = value["name"]
      activity.save
    end
  end

end
