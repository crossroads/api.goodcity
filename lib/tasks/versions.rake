namespace :versions do

  # rake versions:delete
  desc 'clean versions related to orphan offers'
  task delete: :environment do
    select_all_offer_ids = Offer.pluck(:id).join(",")
    ActiveRecord::Base.connection.execute("
      DELETE FROM versions WHERE
      (item_type = 'Offer' AND item_id NOT IN (#{select_all_offer_ids})) OR
      (related_type = 'Offer' AND related_id NOT IN (#{select_all_offer_ids}))
    ")
  end

end
