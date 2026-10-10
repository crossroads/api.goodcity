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
  # The cached GET /package_categories lists each category's type codes, keyed on the categories'
  # own updated_at, so a code rename must touch them.
  after_update :touch_package_categories, if: :saved_change_to_code?

  # Audit trail for the admin editor (create / update / retire). location_id is ignored so a type's
  # default location never shows up in Location.recently_used, which reads every version's
  # object_changes -> 'location_id' regardless of item_type.
  has_paper_trail versions: { class_name: 'Version' }, ignore: [:location_id]

  translates :name, :other_terms

  # Admin-editor validations. They run ONLY in the :admin context
  # (save(context: :admin), used by the new PackageTypesController actions),
  # so no other save path or legacy caller sees a new rule. Format/uniqueness/
  # subform are checked only when changed, so editing other fields of a
  # pre-existing row with unusual legacy data is not blocked.
  validates :code, presence: true, on: :admin
  validates :code, uniqueness: { case_sensitive: false },
                   format: { with: /\A[A-Z0-9]+\z/ },
                   on: :admin, if: :code_changed?
  validates :name_en, presence: true, on: :admin
  validates :subform, inclusion: { in: ['', 'medical', 'electrical', 'computer_accessory', 'computer'] },
                      allow_nil: true, on: :admin, if: :subform_changed?
  validates :default_value_hk_dollar, :customs_value_usd,
            numericality: { greater_than_or_equal_to: 0 }, allow_nil: true, on: :admin
  validates :length, :width, :height,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true, on: :admin

  scope :visible, -> { where(allow_package: true).or(PackageType.box_types).or(PackageType.pallet_types) }
  scope :box_types, -> { where(allow_box: true) }
  scope :pallet_types, -> { where(allow_pallet: true) }

  scope :with_eager_load, -> {
    includes([:location, :subpackage_types, :other_child_package_types, :default_child_package_types, :other_subpackage_types, :default_subpackage_types])
  }

  # Everything that points at a type apart from its own containment rows and category joins (the
  # foreign keys to package_types in db/schema.rb). A type with any of these may be retired, never deleted.
  def usage_counts
    {
      items: items.count,
      packages: packages.count,
      requests: goodcity_requests.count,
      package_sets: PackageSet.where(package_type_id: id).count
    }
  end

  private

  def touch_package_categories
    package_categories.touch_all
  end

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
