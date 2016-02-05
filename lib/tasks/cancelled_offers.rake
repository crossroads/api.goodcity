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

  # rake goodcity:update_cancelled_offers
  desc 'Update cancelled offers'
  task update_cancelled_offers: :environment do
    cancellation_reason = CancellationReason.donor_cancelled
    Offer.where(state: "cancelled").find_in_batches(batch_size: 50).each do |offers|
      offers.each do |offer|
        if offer.created_by == offer.closed_by
          offer.update(cancellation_reason: cancellation_reason)
          puts "updated offer #{offer.id}"
        end
      end
    end
  end

  # rake goodcity:update_closed_offers
  desc 'Update closed offers'
  task update_closed_offers: :environment do
    cancellation_reason = CancellationReason.unwanted
    Offer.where(state: "closed").find_in_batches(batch_size: 50).each do |offers|
      offers.each do |offer|
        offer.update_column(:state, 'cancelled')
        offer.update(cancellation_reason: cancellation_reason)
        puts "updated offer #{offer.id}"
      end
    end
  end
end
