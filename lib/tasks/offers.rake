namespace :goodcity do

  # base_offer_id -> offer in which other offers will be merged
  # merge_offer_ids -> list of comma seperated ids of offers to be merged in base-offer
  # rake goodcity:merge_offers base_offer_id=151 merge_offer_ids="121,122"
  desc 'Merge Offers'
  task merge_offers: :environment do
    merge_offer_ids = ENV['merge_offer_ids']
    base_offer = ENV['base_offer_id'] && Offer.find_by(id: ENV['base_offer_id'])

    if base_offer
      if merge_offer_ids
        merge_offer_ids = merge_offer_ids.split(",").compact
        merge_offers = Offer.where("id IN (?)", merge_offer_ids)
      else
        merge_offers = base_offer.created_by.offers.active.where.not(id: base_offer.id)
      end

      merge_offers.each do |offer|
        base_offer.items << offer.items
        offer.reload.really_destroy!
      end

    end
  end
end
