# rake goodcity:update_orders_packages_data
namespace :goodcity do
  desc 'Update orders_packages'
  task update_orders_packages_data: :environment do
    exclude_ids = OrdersPackage.pluck(:package_id)
    packages = Package.where("order_id is not null or stockit_sent_on is not null").except_package(exclude_ids)
    # code to create log for the rake
    start_time = Time.now
    rake_logger = Logger.new("#{Rails.root}/log/rake_log.log")
    log = ("\n#{'-'*75}")
    rake_logger.info(log)
    log += ("\nRunning rake task 'update_orders_packages_data'....")
    log += ("\nCurrent time: #{start_time}")
    log += ("\nInitial values")
    log += ("\n\tNumber of Packages used to create OrdersPackage =#{packages.count}")
    log += ("\n\tOrdersPackage before rake =#{OrdersPackage.count}")
    log += ("\n\tFirst Package whose OrdersPackage will be created =#{packages.first.id}")
    log += ("\n\tLast Package whose OrdersPackage will be created =#{packages.last.id}")
    rake_logger.info(log)
    first_order = OrdersPackage.last.id + 1
    count = 0
    #end of code to create log for the rake
    packages.find_each(batch_size: 100).each do |package|
      orders_package_state = package.stockit_sent_on ? "dispatched" : "designated"
      orders_package_updated_by_id = orders_package_state == "designated" ? package.stockit_designated_by_id : package.stockit_sent_by_id
      OrdersPackage.create(
        package_id: package.id,
        order_id: package.order_id,
        quantity: package.received_quantity,
        state: orders_package_state,
        updated_by_id: orders_package_updated_by_id,
        sent_on: package.stockit_sent_on,
        created_at: package.stockit_designated_on,
        updated_at: package.updated_at
        )
      count += 1
    end

    # code to create log for the rake
    end_time = Time.now
    log = ("\nTotal time taken: #{end_time-start_time} seconds")
    log += ("\nUpdated values")
    log += ("\n\tNumber of OrdersPackage created =#{count}")
    log += ("\n\tFirst OrdersPackage(id, order, package) that was created =#{OrdersPackage.where(id: first_order).pluck(:id, :order_id, :package_id)}")
    log += ("\n\tLast OrdersPackage(id, order, package) that was created =#{OrdersPackage.pluck(:id, :order_id, :package_id).last}")
    rake_logger.info(log)
    rake_logger.close
    # end of code to create log for the rake
  end
end
