namespace :goodcity do
  task assign_order_id_to_package_and_associated_orders_package: :environment do
    count = 0

    OrdersPackage.where('order_id IS null and package_id IS NOT null').find_each do |orders_package|
      begin
        package = orders_package.package

        latest_designation_name_query = "select (object_changes -> 'designation_name' ->> 1)  from versions where versions.item_id = #{orders_package.package_id} AND versions.item_type = 'Package' AND (object_changes ->> 'designation_name') IS NOT NULL AND (object_changes -> 'designation_name' ->> 1) <> '' ORDER BY versions.created_at DESC LIMIT 1"

        designation_name =  ActiveRecord::Base.connection.execute(latest_designation_name_query).values.flatten[0]
        latest_designation_name =  /^\"\[.*\]\"/.match(designation_name) ? JSON.parse(designation_name)[0] : designation_name
        order_id = Order.find_by_code(latest_designation_name).try(:id)

        puts "updating package = #{package.id} with order_id = #{order_id}"

        if order_id
          orders_package.update(order_id: order_id)
          package.update(order_id: order_id, designation_name: latest_designation_name)
        end

        puts "successfully updated package = #{package.id}"
      rescue Exception => e
        puts e.message
      end
    end
  end
end
