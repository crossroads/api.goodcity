module Goodcity
  class OfferUtils
    def self.merge_offers!(offer_id, merge_offer_ids)
      if (offer = Offer.find_by_id(offer_id)).present?
        merge_offers = offer.created_by.offers.where(id: merge_offer_ids)
        if merge_offers.any?
          merge_offers.each do |merge_offer|
            self.merge_offer!(offer_id: offer_id, other_offer_id: merge_offer.id)
            Rails.logger.info(class: self.class.name, msg: "Merged offer", from_offer_id: merge_offer.id, into_offer_id: offer.id)
          end
        end
      end
    end

    def self.base_offer_states
      %w(submitted under_review reviewed scheduled)
    end

    def self.target_offer_states
      %w(submitted under_review reviewed)
    end

    def self.mergeable_offers(offer)
      Offer
        .where(state: base_offer_states)
        .where.not(id: offer.id)
        .where(created_by_id: offer.created_by_id)
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
      proceed = proceed && base_offer_states.include?(offer.state)
      proceed = proceed && target_offer_states.include?(other_offer.state)

      if proceed
        offer.transaction do
          other_offer.items.each do |item|
            offer.items << item # add to offer
            item.packages.each do |package|
              package.update(offer_id: offer.id)
            end
          end
          Version.where(related_type: "Offer").where(related_id: other_offer.id).each do |version|
            version.update(related_id: offer.id)
          end
        end
        other_offer.reload.really_destroy! if really_destroy
        true
      else
        Rails.logger.info(class: self.class.name, msg: "Unable to merge offer", from_offer_id: other_offer_id, into_offer_id: offer.id)
        false
      end
    end
  end
end
