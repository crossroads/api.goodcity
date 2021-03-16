# rails goodcity:trash_orders_packages
namespace :goodcity do
  desc 'trash all packages from given orders'
  task trash_orders_packages: :environment do
    # trash_order_codes = ["GC-00538", "GC-00910", "GC-00819"]
    # trash_order_ids = [77245, 77894, 77698]

    ActiveRecord::Base.transaction do
      results = ActiveRecord::Base.connection.execute <<-SQL

        update packages_inventories
          set action = 'trash',
            source_id = null,
            source_type = null
          where packages_inventories.id IN (
            SELECT packages_inventories.id
            FROM packages_inventories JOIN (
              SELECT DISTINCT ON (packages_inventories.source_id) source_id,
                max(packages_inventories.id) AS id
                FROM packages_inventories
                WHERE packages_inventories.source_type = 'OrdersPackage' AND
                  packages_inventories.source_id IN (
                    select orders_packages.id from orders_packages where orders_packages.order_id IN (77245, 77894, 77698)
                  )
                GROUP BY source_id
            ) latest_entry
            ON packages_inventories.id = latest_entry.id
            AND packages_inventories.source_id = latest_entry.source_id
            where packages_inventories.action = 'dispatch' AND
              packages_inventories.source_id IN (
                select orders_packages.id from orders_packages where orders_packages.order_id IN (77245, 77894, 77698)
              )
          );

        delete from packages_inventories
          where packages_inventories.source_type = 'OrdersPackage' AND
                packages_inventories.source_id IN (
                  select orders_packages.id from orders_packages where orders_packages.order_id IN (77245, 77894, 77698)
                );

        delete from orders_packages
          where orders_packages.id in (
            select orders_packages.id from orders_packages where orders_packages.order_id IN (77245, 77894, 77698)
          );

      SQL

      raise ActiveRecord::Rollback if results.error_message.present?
    end
  end
end
