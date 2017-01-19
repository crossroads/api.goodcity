namespace :goodcity do

  # rake goodcity:update_orders_packages_data
  desc 'Update orders_packages'
  task update_orders_packages_data: :environment do
    exclude_ids = OrdersPackage.pluck(:package_id)
    packages = Package.where("order_id is not null or stockit_sent_on is not null").except_package(exclude_ids)
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
    end
  end
end
