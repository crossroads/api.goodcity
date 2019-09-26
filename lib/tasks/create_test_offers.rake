# rake 'goodcity:create_test_offers[5]'
namespace :goodcity do
  desc 'Add new testing offers'
  # creating some cancelled or closed offers for testing fallback story
  task :create_test_offers, %i[count] => [:environment] do |_task, args|
    log = Goodcity::RakeLogger.new("create_test_offers")
    states = %w[cancelled closed].freeze
    user_ids = User.limit(20).pluck(:id)
    donor_conditions = DonorCondition.pluck(:id)
    cancellation_reasons = CancellationReason.pluck(:id)
    package_types = PackageType.limit(20).pluck(:id)
    reviewer_id = User.find_by_mobile("+85291111111").id
    bar = RakeProgressbar.new(args[:count].to_i)
    count = 0
    created_offers_ids = []

    args[:count].to_i.times do |a|
      offer = Offer.new( state: states.sample, created_by_id: user_ids.sample, cancellation_reason_id: cancellation_reasons.sample, reviewed_by_id: reviewer_id, closed_by_id: reviewer_id )
      if offer.save
        count += 1
        bar.inc
        created_offers_ids << offer.id
        offer.items.create(donor_condition_id: donor_conditions.sample, donor_description: "testing fallback #{a}", state: "submitted", package_type_id: package_types.sample)
      else
        log.info("Errors: #{offer.errors.full_messages}")
      end
    end
    log.info("#{count} offers created.")
    log.info("Offers created Id's => #{created_offers_ids}")
    bar.finished
  end
end
