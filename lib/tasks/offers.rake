require 'goodcity/offer_utils'

namespace :goodcity do

  desc <<-DESC
  Merge one or more offers into another offer. All offers must belong to the same user.
  EXAMPLE USAGE: rake goodcity:merge_offers OFFER_ID=151 MERGE_OFFER_IDS='121,122'
  OFFER_ID: offer into which other offers will be merged
  MERGE_OFFER_IDS: comma separated list of offer ids to be merged into OFFER_ID"
  DESC
  task merge_offers: [:environment, :setup_logger] do
    offer_id = (ENV['OFFER_ID'] || "").strip
    merge_offer_ids = (ENV['MERGE_OFFER_IDS'] || "").strip.split(",").compact.map(&:strip).uniq
    if offer_id.blank?
      log_and_exit("Please specify an OFFER_ID.")
    elsif merge_offer_ids.blank?
     log_and_exit("Please specify MERGE_OFFER_IDS.")
    else
      Goodcity::OfferUtils.merge_offers!(offer_id, merge_offer_ids)
    end
  end

  task setup_logger: :environment do
    # Rails.logger.* redirected to STDOUT
    logger           = Logger.new(STDOUT)
    logger.level     = Logger::INFO
    Rails.logger     = logger
  end

end
