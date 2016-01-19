module Goodcity
  class OfferUtils
    def self.merge_offers(offer_id, merge_offer_ids)

      if (offer = Offer.find_by_id(offer_id)).present?
        merge_offer_ids = merge_offer_ids.split(",").compact.map(&:strip).uniq
        merge_offers = offer.created_by.offers.where(id: merge_offer_ids)
        if merge_offers.any?
          merge_offers.each do |dup|
            Offer.transaction do
              offer.merge!(dup)
              dup.reload.really_destroy!
            end
            Rails.logger.info "Merged offer #{dup.id} into offer #{offer.id}"
          end
        else
          Rails.logger.info("No offers to merge were found.")
        end
      else
        Rails.logger.warn("Could not find offer id #{offer_id}")
      end

    end
  end
end
