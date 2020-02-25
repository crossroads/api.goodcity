class StorageType < ActiveRecord::Base
  has_many :packages

  def self.storage_type_ids(name)
    package_storage_type_id = find_by(name: "Package").id
    if name == "Pallet"
      [ package_storage_type_id, find_by(name: "Box").id]
    else
      [ package_storage_type_id ]
    end
  end
end
