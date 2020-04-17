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
    def packages_contained_in(container)
      cid = Utils.to_id(container)
      ids = PackagesInventory.
        where(source_type: 'Package', source_id: cid, action: ['pack', 'unpack']).
        group('package_id').
        having('SUM(quantity) < 0').
        select('DISTINCT package_id').
        pluck(:package_id)
      Package.where(id: ids)
    end

    ##
    # Returns the boxes/pallets which contain the specified package
    #
    # @param {Package|string} package or its id
    # @returns {Package[]}
    #
    def containers_of(package)
      pid = Utils.to_id(package)
      ids = PackagesInventory.
        where(source_type: 'Package', package_id: pid, action: ['pack', 'unpack']).
        group('source_id').
        having('SUM(quantity) < 0').
        select('DISTINCT source_id').
        pluck(:source_id)
      Package.where(id: ids)
    end
  end
end
