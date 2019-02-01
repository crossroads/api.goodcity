# rake goodcity:copy_authorised_by_id
namespace :goodcity do
  task copy_authorised_by_id: :environment do
    i = 0
    log = Goodcity::RakeLogger.new("copy_authorised_by_id")
    updated_order_ids = []
    not_updated_order_ids = []
    Order.where('authorised_by_id IS not null').find_each do |order|
      order.submitted_by_id = order.authorised_by_id
      if order.save
        updated_order_ids << order.id
        i += 1
      else
        not_updated_order_ids << order.id
      end
    end
    log.info(": #{i} orders updated")
    log.info("updated record ids: #{updated_order_ids}")
    log.info("not updated record ids: #{not_updated_order_ids}")
  end
end
