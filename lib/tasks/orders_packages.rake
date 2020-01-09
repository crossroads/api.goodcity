namespace :goodcity do
  namespace :orders_packages do
    desc <<-DESC
      Initializes the dispatched_quantity field of orders_packages.
      If the orders_package is marked as dispatched, sets the `dispatched_quantity` field to the quantity designated
    DESC
    task init_dispatched_quantity: :environment do
      count = 0
      OrdersPackage.dispatched.find_each do |orders_package|
        orders_package.update(dispatched_quantity: orders_package.quantity)
        count += 1
      end
      puts "Task completed. #{count} records modified"
    end
  end
end
