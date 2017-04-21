namespace :goodcity do

  desc 'Update orders_packages'
  task update_orders_packages_data: :environment do
    exclude_ids = OrdersPackage.pluck(:package_id)
    packages = Package.where("order_id is not null or stockit_sent_on is not null").except_package(exclude_ids)

    # code to create log for the rake
    x = Time.now
    File.open("rake_log.txt", "a+"){|f|
      f << "\n#{'-'*80}"
      f << "\nRunning rake task 'update_orders_packages_data'...."
      f << "\nCurrent time: #{x}"
      f << "\nInitial values"
      f << "\n\tNumber of Packages used to create OrdersPackage =#{packages.count}"
      f << "\n\tOrdersPackage before rake =#{OrdersPackage.count}"
      f << "\n\tFirst Package whose OrdersPackage will be created =#{packages.first}"
      f << "\n\tLast Package whose OrdersPackage will be created =#{packages.last}"
    }
    first_order = OrdersPackage.last.id+1
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
    end

    # code to create log for the rake
    y=Time.now
    File.open("rake_log.txt", "a+"){|f|
      f << "\nTotal time taken: #{x-y} seconds"
      f << "\nUpdated values"
      f << "\n\tNumber of OrdersPackage created =#{OrdersPackage.where("id >= #{first_order}").count}"
      f << "\n\tFirst OrdersPackage that was created =#{OrdersPackage.find(first_order)}"
      f << "\n\tLast OrdersPackage that was created =#{OrdersPackage.last}"
    }
    # end of code to create log for the rake
  end
end
