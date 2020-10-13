class StorageType < ApplicationRecord
  has_many :packages

  TYPES = {
    box: 'Box',
    pallet: 'Pallet',
    package: 'Package'
  }.freeze

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
    package_storage_type_id = find_by(name: TYPES[:package]).id
    if name == TYPES[:pallet]
      [package_storage_type_id, find_by(name: TYPES[:box]).id]
    else
      [package_storage_type_id]
    end
  end

  class << self
    TYPES.keys.each do |attr|
      define_method "#{attr}_type_id" do
        find_by(name: TYPES[attr])&.id
      end
    end
  end
end
