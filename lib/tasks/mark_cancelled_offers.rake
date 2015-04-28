namespace :goodcity do

  # rake goodcity:mark_cancelled_offers
  desc 'Mark soft-deleted offers as cancelled'
  task mark_cancelled_offers: :environment do

    Offer.only_deleted.find_in_batches(batch_size: 50).each do |offers|
      offers.each do |offer|
        deletedTime = offer.deleted_at
        offer.restore(recursive: true)
        offer.cancel
        offer.update_column(:cancelled_at, deletedTime)
        puts "updated offer #{offer.id}"
      end
    end

  end
end
