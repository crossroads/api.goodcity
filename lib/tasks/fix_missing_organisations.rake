#rake goodcity:fix_missing_organisations

namespace :goodcity do
  task fix_missing_organisations: :environment do
    count = 0
    log = Goodcity::RakeLogger.new("fix_missing_organisations")
    #get all the gc orders without organisation and not draft draft orders
    Order.where("orders.state <> ? and orders.organisation_id IS NULL and orders.created_by_id IS NOT NULL and code ILIKE ?","draft", "GC-%").find_each do |order|
      creator_organisations = order.created_by&.organisations
      next unless creator_organisations
      if order.update(organisation_id: creator_organisations.first.id)
        count += 1
        print "."
      end
    end
    log.info(": #{count} orders updated")
    puts "#{count} orders updated"
    log.close
  end
end
