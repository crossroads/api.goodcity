##
# Reads the PackagesInventory to simplify the logic of having packages
# nested one into the other
#
module PackageBoxing
  extend ActiveSupport::Concern

  class_methods do
    ##
    # Returns the packages that are nested inside the current package
    #
    # @returns {Package[]}
    #
    def packages_contained_in(package)
      id = Utils.to_id(package)

      sql = <<-SQL
        SELECT DISTINCT pi.package_id
        FROM packages_inventories pi
        WHERE pi.source_type = 'Package' AND pi.source_id = #{id}
        AND pi.action IN ('pack', 'unpack')
        GROUP BY pi.package_id
        HAVING sum(pi.quantity) < 0
      SQL

      ids = PackagesInventory.connection.execute(sql).map{ |res| res['package_id'] }.uniq.compact
      Package.where(id: ids)
    end

    ##
    # Returns the boxes/pallets which contain the specified package
    #
    # @param {Package|string} package or its id
    # @returns {Package[]}
    #
    def containers_of(package)
      id = Utils.to_id(package)

      sql = <<-SQL
        SELECT DISTINCT pi.source_id
        FROM packages_inventories pi
        WHERE (
          pi.source_type = 'Package' AND
          pi.package_id = #{id} AND
          pi.action IN ('pack', 'unpack')
        )
        GROUP BY pi.source_id
        HAVING sum(pi.quantity) < 0
      SQL

      ids = PackagesInventory.connection.execute(sql).map{ |res| res['source_id'] }.uniq.compact
      Package.where(id: ids)
    end
  end
end
