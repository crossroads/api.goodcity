#
# require 'goodcity/package_destroyer'
# Goodcity::PackageDestroyer.destroy(package)

module Goodcity
  class PackageDestroyer

    def self.destroy(package)
      id = package.id

      ActiveRecord::Base.transaction do
        [
          :packages_locations,
          :packages_inventories,
          :orders_packages,
          :requested_packages,
          :offers_packages
        ].each do |table|
          # Delete associated records
          ActiveRecord::Base.connection.execute("DELETE FROM #{table} WHERE package_id = #{id}");
        end

        ActiveRecord::Base.connection.execute("DELETE FROM packages WHERE id = #{id}");
      end
    end
  end
end