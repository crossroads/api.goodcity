class StorageType < ApplicationRecord
  has_many :packages

  def singleton?
    capped? && max_unit_quantity.eql?(1)
  end

  def capped?
    max_unit_quantity.present? && max_unit_quantity.positive?
  end

  def unit?
    name.eql?('Package')
  end

  def aggregate?
    !unit?
  end

  def self.storage_type_ids(name)
    package_storage_type_id = find_by(name: "Package").id
    if name == "Pallet"
      [ package_storage_type_id, find_by(name: "Box").id]
    else
      [ package_storage_type_id ]
    end
  end
end
