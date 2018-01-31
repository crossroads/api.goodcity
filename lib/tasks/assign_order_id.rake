require "goodcity/rake_logger"

namespace :goodcity do
  task assign_order_id_to_package_and_associated_orders_package: :environment do
    log = Goodcity::RakeLogger.new("assign_order_id")

    count = 0
    not_updated_packages = []
    not_updated_orders_packages = []

    OrdersPackage.where('order_id IS null and package_id IS NOT null').find_each do |orders_package|
      begin
        package = orders_package.package

        latest_designation_name_query = "select (object_changes -> 'designation_name' ->> 1)  from versions where versions.item_id = #{orders_package.package_id} AND versions.item_type = 'Package' AND (object_changes ->> 'designation_name') IS NOT NULL AND (object_changes -> 'designation_name' ->> 1) <> '' ORDER BY versions.created_at DESC LIMIT 1"

        designation_name =  ActiveRecord::Base.connection.execute(latest_designation_name_query).values.flatten[0]
        latest_designation_name =  /^\"\[.*\]\"/.match(designation_name) ? JSON.parse(designation_name)[0] : designation_name
        order_id = Order.find_by_code(latest_designation_name).try(:id)

        puts "updating package = #{package.id} with order_id = #{order_id}"

        if order_id
          log.info("\n\t updating package_id = #{package.id} and orders_package_id = #{orders_package.id}")
          orders_package.order_id = order_id
          package.order_id = order_id
          package.designation_name = latest_designation_name
          if orders_package.save and package.save
            log.info("\n\t updated package_id = #{package.id} inventory_number = #{package.inventory_number} designation = #{package.designation_name} orders_package_id = #{orders_package.id}")
            count += 1
          else
            not_updated_packages << package.id
            not_updated_orders_packages << orders_package_id.id
          end
        end

        puts "successfully updated package = #{package.id}"
      rescue Exception => e
        log.error "(#{e.message})"
        puts e.message
      end
    end

    log.info("\n\t Total number of packages updated =#{count}")
    log.debug("\n\t List of orders_packages which are not update = #{not_updated_packages}")
    log.debug("\n\t List of packages which are not updated = #{not_updated_packages}")
  end
end
