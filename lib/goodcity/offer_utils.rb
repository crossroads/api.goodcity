module Goodcity
  class OfferUtils
    def self.merge_offers!(offer_id, merge_offer_ids)
      if (offer = Offer.find_by_id(offer_id)).present?
        merge_offers = offer.created_by.offers.where(id: merge_offer_ids)
        if merge_offers.any?
          merge_offers.each do |merge_offer|
            self.merge_offer!(offer_id: offer_id, other_offer_id: merge_offer.id)
            Rails.logger.info "Merged offer #{merge_offer.id} into offer #{offer.id}"
          end
        else
          Rails.logger.info("No offers to merge were found.")
        end
      else
        Rails.logger.warn("Could not find offer id #{offer_id}")
      end
    end

    # Merges the items from one offer into another
    # - Returns true if successful and false if not
    # - Doesn't allow merges of offers from other users as this would lose contact details
    # - Restricts to certain offer states
    # - Use ActiveRecord methods so that callbacks are fired (e.g. for push_update)
    def self.merge_offer!(options = {})
      offer_id = options[:offer_id]
      offer = Offer.find(offer_id)
      other_offer_id = options[:other_offer_id]
      other_offer = Offer.find(other_offer_id)
      really_destroy = options[:really_destroy] || true

      # pre-flight checks
      proceed = offer.created_by_id == other_offer.created_by_id
      mergeable_statuses = %w(submitted under_review reviewed)
      proceed = proceed && mergeable_statuses.include?(offer.state)
      proceed = proceed && mergeable_statuses.include?(other_offer.state)

      if proceed
        offer.transaction do
          other_offer.items.each do |item|
            offer.items << item # add to offer
            item.packages.each do |package|
              package.update(offer_id: offer.id)
            end
            item.messages.each do |message|
              message.update(offer_id: offer.id)
            end
          end
          Version.where(related_type: "Offer").where(related_id: other_offer.id).each do |version|
            version.update(related_id: offer.id)
          end
        end
        other_offer.reload.really_destroy! if really_destroy
        true
      else
        Rails.logger.info("Unable to merge offer #{other_offer_id} into offer #{offer.id}.")
        false
      end
    end

  end
end
