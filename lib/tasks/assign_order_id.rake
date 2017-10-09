namespace :goodcity do
  task assign_order_id_to_package_and_associated_orders_package: :environment do
    OrdersPackage.where('order_id IS null and package_id IS NOT null').find_each do |orders_package|
      package = orders_package.package

      latest_designation_name_query = "select (object_changes -> 'designation_name' ->> 1)  from versions where versions.item_id = #{orders_package.package_id} AND versions.item_type = 'Package' AND (object_changes ->> 'designation_name') IS NOT NULL AND (object_changes -> 'designation_name' ->> 1) <> '' ORDER BY versions.created_at DESC LIMIT 1"

      latest_designation_name =  ActiveRecord::Base.connection.execute(latest_designation_name_query).values.first
      order_id = Order.find_by_code(latest_designation_name).try(:id)

      if order_id
        orders_package.update(order_id: order_id)
        package.update(order_id: order_id, designation_name: latest_designation_name)
      end
    end
  end
end
