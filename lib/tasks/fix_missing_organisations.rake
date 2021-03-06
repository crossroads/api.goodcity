# rake goodcity:fix_missing_organisations

namespace :goodcity do
  task fix_missing_organisations: :environment do
    count = 0
    log = Goodcity::RakeLogger.new("fix_missing_organisations")
    # get all the gc orders without organisation and not draft draft orders
    Order
      .where(organisation_id: nil)
      .where.not(created_by_id: nil, state: 'draft')
      .where("code ILIKE ?", "GC-%").find_each do |order|
      creator_organisations = order.created_by&.organisations
      next if creator_organisations.blank?
      if order.update(organisation_id: creator_organisations.first.id)
        count += 1
        print "."
      end
    end
    log.info(": #{count} orders updated")
    log.close
    puts "#{count} orders updated"
  end
end
