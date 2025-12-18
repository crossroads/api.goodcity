class Package < ApplicationRecord
  has_paper_trail versions: { class_name: 'Version' }, meta: { related: :offer }
  include Paranoid
  include StateMachineScope
  include PushUpdatesMinimal
  include AutoFavourite
  include ShareSupport

  include PackageFiltering
  include LocationOperations
  include DesignationOperations
  include StockOperations
  include Watcher
  include Secured
  include ValuationCalculator

  BROWSE_ITEM_STATES = %w(accepted submitted)
  BROWSE_OFFER_EXCLUDE_STATE = %w(cancelled inactive closed draft)
  SETTINGS_KEYS = %w[stock.enable_box_pallet_creation].freeze

  validates_with SettingsValidator, settings: { keys: SETTINGS_KEYS }, if: :box_or_pallet?
  belongs_to :item
  belongs_to :package_set

  belongs_to :detail, polymorphic: true, dependent: :destroy, required: false
  belongs_to :package_type, inverse_of: :packages
  belongs_to :donor_condition
  belongs_to :pallet
  belongs_to :box
  belongs_to :order
  belongs_to :storage_type, required: false
  belongs_to :stockit_designated_by, class_name: 'User'
  belongs_to :stockit_sent_by, class_name: 'User'
  belongs_to :stockit_moved_by, class_name: 'User'
  belongs_to :package_category_override, class_name: 'PackageCategory', foreign_key: 'package_category_override_id', optional: true

  has_many   :packages_locations, inverse_of: :package, dependent: :destroy
  has_many   :locations, through: :packages_locations
  has_many   :images, as: :imageable, dependent: :destroy
  has_many   :orders_packages, dependent: :destroy
  has_many   :requested_packages, dependent: :destroy
  has_many   :messages, as: :messageable, dependent: :destroy
  has_many   :offers_packages
  has_many   :offers, through: :offers_packages
  has_many   :package_actions, -> { where action: PackagesInventory::INVENTORY_ACTIONS }, class_name: "PackagesInventory"

  before_destroy :remove_inventory_number, if: :inventory_number
  before_create :set_default_values
  before_save :reset_value_hk_dollar, if: :value_hk_dollar_changed?
  before_save :save_inventory_number, if: :inventory_number_changed?
  before_save :set_favourite_image, if: :valid_favourite_image_id?
  before_save :set_package_category_override_id

  # Live update rules
  after_save :push_changes
  after_destroy :push_changes
  push_targets do |record|
    chans = [Channel::STOCK_CHANNEL]
    chans << Channel::STAFF_CHANNEL if record.item_id
    chans << Channel::BROWSE_CHANNEL if record.allow_web_publish || record.allow_web_publish_before_last_save
    chans
  end

  validates :package_type_id, presence: true
  validates :value_hk_dollar, presence: true, if: -> { !box_or_pallet? }
  validates :notes, presence: true
  validates :max_order_quantity, numericality: { :allow_blank => true, greater_than_or_equal_to: 0 }
  validates :on_hand_quantity, numericality: { greater_than_or_equal_to: 0 }
  validates :available_quantity, numericality: { greater_than_or_equal_to: 0 }
  validates :designated_quantity, numericality: { greater_than_or_equal_to: 0 }
  validates :dispatched_quantity, numericality: { greater_than_or_equal_to: 0 }
  validates :received_quantity, numericality: { greater_than: 0 }
  validates :on_hand_boxed_quantity, numericality: { greater_than_or_equal_to: 0 }
  validates :on_hand_palletized_quantity, numericality: { greater_than_or_equal_to: 0 }
  validates :weight, :pieces, numericality: { allow_blank: true, greater_than: 0 }
  validates :width, :height, :length, numericality: { allow_blank: true, greater_than_or_equal_to: 0 }
  validate  :validate_set_id, on: [:create, :update]
  validate  :validate_package_type, on: [:update]
  validates_uniqueness_of :inventory_number, if: :should_validate_inventory_number?

  scope :donor_packages, ->(donor_id) { joins(item: [:offer]).where(offers: { created_by_id: donor_id }) }
  scope :received, -> { where(state: 'received') }
  scope :expecting, -> { where(state: 'expecting') }
  scope :inventorized, -> { where.not(inventory_number: nil) }
  scope :published, -> { where(allow_web_publish: true) }
  scope :latest, -> { order('id desc') }
  scope :except_package, ->(id) { where.not(id: id) }
  scope :undesignated, -> { where(order_id: nil) }
  scope :not_multi_quantity, -> { where("received_quantity = 1") }
  scope :exclude_designated, ->(designation_id) {
    where("order_id <> ? OR order_id IS NULL", designation_id)
  }

  # used on PackagesController#index
  scope :with_eager_load, -> {
    includes([
      :images, :item, {packages_locations: :location}, :orders_packages, :storage_type,
      package_type: [:location, :subpackage_types, :other_child_package_types, :default_child_package_types, :other_subpackage_types, :default_subpackage_types]
    ])
  }

  accepts_nested_attributes_for :packages_locations, :detail, allow_destroy: true, limit: 1

  attr_accessor :skip_set_relation_update, :request_from_admin, :detail_attributes

  auto_favourite(relations: ['package_type'], enabled: true)

  # ---------------------
  # Computed properties
  # ---------------------

  watch [PackagesInventory, OrdersPackage] do |record|
    PackagesInventory::Computer.update_package_quantities!(record.package)
  end

  # ---------------------
  # Security
  # ---------------------

  def inventory_lock
    PackagesInventory.secured_transaction(id) { yield }
  end

  # ---------------------
  # States
  # ---------------------

  # Workaround to set initial state for the state_machine
  # StateMachine has Issue with rails 4.2, it does not set initial state by default
  # refer - https://github.com/pluginaweek/state_machine/issues/334
  after_initialize do
    self.state ||= :expecting
  end

  state_machine :state, initial: :expecting do
    state :expecting, :missing, :received

    event :mark_received do
      transition [:expecting, :missing, :received] => :received
    end

    event :mark_missing do
      transition [:expecting, :missing, :received] => :missing
    end

    before_transition on: :mark_received do |package|
      package.received_at = Time.now
      package.assign_offer if package.inventory_number.present? && package.item.present?
    end

    before_transition on: :mark_missing do |package|
      package.delete_associated_packages_locations
      package.received_at = nil
      package.location_id = nil
      package.allow_web_publish = false
      true
    end
  end

  def quantity_contained_in(container_id)
    PackagesInventory::Computer.quantity_contained_in(package: self, container: Package.find(container_id))
  end

  def self.total_quantity_in(pkg_id)
    PackagesInventory::Computer.total_quantity_in(pkg_id)
  end

  def designation
    orders_packages.designated.first
  end

  def delete_associated_packages_locations
    packages_locations.destroy_all
  end

  def unpublish
    update(allow_web_publish: false)
  end

  def publish
    update(allow_web_publish: true)
  end

  def published?
    allow_web_publish.present?
  end

  def should_validate_inventory_number?
    inventory_number.present?
  end

  # Required by PushUpdates and PaperTrail modules
  def offer
    item.try(:offer)
  end

  def total_assigned_quantity
    total_quantity = 0
    if (associated_orders_packages = orders_packages.get_designated_and_dispatched_packages(id).presence)
      associated_orders_packages.each do |orders_package|
        total_quantity += orders_package.quantity
      end
    end
    total_quantity
  end

  def self.browse_public_packages
    join = <<-SQL
      LEFT OUTER JOIN items as pkg_items ON pkg_items.id = packages.item_id AND pkg_items.deleted_at IS NULL
      LEFT OUTER JOIN offers as pkg_offers ON pkg_offers.id = pkg_items.offer_id AND pkg_offers.deleted_at IS NULL
    SQL

    query = <<-SQL
      packages.inventory_number IS NOT NULL AND
      packages.available_quantity > 0
    SQL

    joins(join).published.where(query,
      allowed_items: BROWSE_ITEM_STATES,
      excluded_offers: BROWSE_OFFER_EXCLUDE_STATE
    )
  end

  def valid_favourite_image_id?
    item_image_ids = self.item && self.item.images.pluck(:id) || []
    image_ids = self.images.pluck(:id).concat(item_image_ids)
    favourite_image_id_changed? &&
      favourite_image_id.present? &&
      image_ids.include?(favourite_image_id)
  end

  def set_favourite_image
    current_image = images.find_by(id: favourite_image_id)

    if !current_image
      item_image = item.images.find_by(id: favourite_image_id)

      if item_image
        current_image = images.find_by(cloudinary_id: item_image.cloudinary_id) ||
          Image.create(item_image.attributes.slice("cloudinary_id", "angle"))
        self.images << current_image
      end
    end

    if current_image
      current_image.update_column(:favourite, true)
      self.favourite_image_id = current_image.id
    end
  end

  def storage_type_name
    storage_type&.name
  end

  def box?
    storage_type_name&.eql?('Box')
  end

  def box_or_pallet?
    %w[Box Pallet].include?(storage_type_name)
  end

  def assign_offer
    offers_packages.where(offer_id: item.offer_id).first_or_create
  end

  private

  #
  # Ensure boxes and pallets are not part of a set
  #
  def validate_set_id
    errors.add(:errors, I18n.t('package_sets.no_box_in_set')) if package_set_id.present? && storage_type&.aggregate?
  end

  def set_default_values
    self.donor_condition ||= item.try(:donor_condition)
    self.grade ||= "B"
    self.saleable ||= offer.try(:saleable) || false
    true
  end

  def reset_value_hk_dollar
    self.value_hk_dollar = value_hk_dollar && value_hk_dollar.round(2)
  end

  def save_inventory_number
    if gc_inventory_number
      InventoryNumber.where(code: inventory_number).first_or_create
    end
  end

  def remove_inventory_number
    if gc_inventory_number
      InventoryNumber.find_by(code: inventory_number).try(:destroy)
    end
  end

  def gc_inventory_number
    inventory_number && inventory_number.match(/^[0-9]+$/)
  end

  def validate_package_type
    return unless box_or_pallet?
    return unless package_type_id_changed?

    count = PackagesInventory.packages_contained_in(self).count
    errors.add(:error, I18n.t('box_pallet.errors.cannot_change_type')) if count.positive?
  end

  def set_package_category_override_id
    # TEMP: In case we want the package to show up under a different browse category
    self.package_category_override_id =
      case self.comment
      when /BrowseCategoryTaiPo:Furniture-Beds and Mattresses/i
        PackageCategory.find_by(name_en: "Furniture Beds")&.id
      when /BrowseCategoryTaiPo:Furniture-Seating/i
        PackageCategory.find_by(name_en: "Furniture Seating")&.id
      when /BrowseCategoryTaiPo:Furniture-Storage/i
        PackageCategory.find_by(name_en: "Furniture Storage")&.id
      when /BrowseCategoryTaiPo:Furniture-Tables/i
        PackageCategory.find_by(name_en: "Furniture Tables")&.id
      when /BrowseCategoryTaiPo:Kitchen items/i
        PackageCategory.find_by(name_en: "Kitchen items")&.id
      when /BrowseCategoryTaiPo:Large household electrical items/i
        PackageCategory.find_by(name_en: "Large electrical items")&.id
      when /BrowseCategoryTaiPo:Small household electrical items/i
        PackageCategory.find_by(name_en: "Small electrical items")&.id
      when /BrowseCategoryTaiPo:Others/i
        PackageCategory.find_by(name_en: "Others")&.id
      else
        nil
      end
  end

end
