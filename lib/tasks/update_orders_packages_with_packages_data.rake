require "goodcity/rake_logger"

namespace :goodcity do
  desc 'Update orders_packages'
  task update_orders_packages_data: :environment do
    PaperTrail.enabled = false
    packages = Package.where("order_id is not null or stockit_sent_on is not null")
    packages = packages.where(received_quantity: 1) # singletons only
    count = 0
    bar = RakeProgressbar.new(packages.count)
    orders_package_package_ids = OrdersPackage.pluck("DISTINCT package_id")
    ActiveRecord::Base.record_timestamps = false
    packages.find_each do |package|
      bar.inc
      next if orders_package_package_ids.include?(package.id)
      orders_package_state = package.stockit_sent_on ? "dispatched" : "designated"
      orders_package_updated_by_id = orders_package_state == "designated" ? package.stockit_designated_by_id : package.stockit_sent_by_id
      created_at = [package.stockit_designated_on, package.stockit_sent_on].compact.min || package.created_at || Date.today
      updated_at = [package.stockit_designated_on, package.stockit_sent_on].compact.max || package.updated_at || Date.today
      OrdersPackage.create(
        package_id: package.id,
        order_id: package.order_id,
        quantity: package.received_quantity,
        state: orders_package_state,
        updated_by_id: orders_package_updated_by_id,
        sent_on: package.stockit_sent_on,
        created_at: created_at,
        updated_at: updated_at
        )
      count += 1
    end
    ActiveRecord::Base.record_timestamps = true
    bar.finished

    log = Goodcity::RakeLogger.new("update_orders_packages_data")
    log.info("\n\tUpdated Number of OrdersPackage created =#{count}")
    log.debug("\n\tUpdated First OrdersPackage(id, order, package) that was created =#{OrdersPackage.pluck(:id, :order_id, :package_id).first}")
    log.debug("\n\tUpdated Last OrdersPackage(id, order, package) that was created =#{OrdersPackage.pluck(:id, :order_id, :package_id).last}")
    log.close
  end
end
