# rake 'goodcity:create_test_offers[5, +85291111111]'

namespace :goodcity do
  desc 'Add new testing offers'
  # creating some cancelled or closed offers for testing fallback story
  task :create_test_offers, %i[count user_mobile] => [:environment] do |_task, args|
    log = Goodcity::RakeLogger.new("create_test_offers")
    STATES = %w[cancelled closed].freeze
    user_ids = User.limit(20).pluck(:id)
    donor_conditions_ids = DonorCondition.pluck(:id)
    cancellation_reasons_ids = CancellationReason.pluck(:id)
    package_types_ids = PackageType.limit(20).pluck(:id)
    reviewer_id = User.find_by_mobile(args[:user_mobile])&.id
    bar = RakeProgressbar.new(args[:count].to_i)
    created_offers_ids = []
    args[:count].to_i.times do |a|
      offer = Offer.new(
        state: STATES.sample,
        created_by_id: user_ids.sample,
        cancellation_reason_id: cancellation_reasons_ids.sample,
        reviewed_by_id: reviewer_id,
        closed_by_id: reviewer_id)

      if offer.save
        created_offers_ids << offer.id
        bar.inc
        begin
          offer.items.create(
            donor_condition_id: donor_conditions_ids.sample,
            donor_description: "testing fallback #{a}",
            state: "submitted",
            package_type_id: package_types_ids.sample)
        rescue => exception
          log.info("Exception: #{exception}")
        end
      else
        log.info("Errors: #{offer.errors.full_messages}") && next
      end
    end
    bar.finished
    log.info("#{created_offers_ids.size} offers created.")
    log.info("Offers created Id's => #{created_offers_ids}")
  end
end
