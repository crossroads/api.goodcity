class PackageType < ApplicationRecord
  include CacheableJson

  belongs_to :location
  has_many :subpackage_types
  has_many :child_package_types, through: :subpackage_types, source: :child_package_type

  has_many :default_subpackage_types, -> { where is_default: true }, class_name: :SubpackageType
  has_many :default_child_package_types, through: :default_subpackage_types, source: :default_child_package_type

  has_many :other_subpackage_types, -> { where is_default: false }, class_name: :SubpackageType
  has_many :other_child_package_types, through: :other_subpackage_types, source: :other_child_package_type

  has_many :items, inverse_of: :package_type
  has_many :packages, inverse_of: :package_type
  has_many :goodcity_requests

  has_many :package_categories_package_types
  has_many :package_categories, through: :package_categories_package_types

  after_create :create_default_sub_package_type, unless: :child_package_type?

  translates :name, :other_terms

  scope :visible, -> { where(allow_package: true).or(PackageType.box_types).or(PackageType.pallet_types) }
  scope :box_types, -> { where(allow_box: true) }
  scope :pallet_types, -> { where(allow_pallet: true) }

  scope :with_eager_load, -> {
    eager_load([:location, :subpackage_types, :other_child_package_types, :default_child_package_types, :other_subpackage_types, :default_subpackage_types])
  }

  private

  def child_package_type?
    default_child_package_types.exists?
  end

  def create_default_sub_package_type
    SubpackageType.create(
      package_type: self,
      child_package_type: self,
      is_default: true
    )
  end
end
