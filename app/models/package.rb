class Package < ApplicationRecord
  has_paper_trail class_name: 'Version', meta: { related: :offer }
  include Paranoid
  include StateMachineScope
  include PushUpdatesMinimal
  include RollbarSpecification
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
  has_many :locations, through: :packages_locations

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

  has_many   :packages_locations, inverse_of: :package, dependent: :destroy
  has_many   :images, as: :imageable, dependent: :destroy
  has_many   :orders_packages, dependent: :destroy
  has_many   :requested_packages, dependent: :destroy
  has_many   :messages, as: :messageable, dependent: :destroy
  has_many   :offers_packages
  has_many   :offers, through: :offers_packages
  has_many   :package_actions, -> { where action: PackagesInventory::INVENTORY_ACTIONS }, class_name: "PackagesInventory"

  before_destroy :delete_item_from_stockit, if: :inventory_number
  before_create :set_default_values
  after_commit :update_stockit_item, on: :update, if: :updated_received_package?
  before_save :save_inventory_number, if: :inventory_number_changed?
  before_save :assign_stockit_designated_by, if: :unless_dispatch_and_order_id_changed_with_request_from_stockit?
  before_save :assign_stockit_sent_by_and_designated_by, if: :dispatch_from_stockit?
  before_save :set_favourite_image, if: :valid_favourite_image_id?

  # Live update rules
  after_save :push_changes
  after_destroy :push_changes
  push_targets do |record|
    chans = [ Channel::STOCK_CHANNEL ]
    chans << Channel::STAFF_CHANNEL if record.item_id
    chans << Channel::BROWSE_CHANNEL if (record.allow_web_publish || record.allow_web_publish_was)
    chans
  end

  validates :package_type_id, presence: true
  validates :on_hand_quantity, numericality: { greater_than_or_equal_to: 0 }
  validates :available_quantity, numericality: { greater_than_or_equal_to: 0 }
  validates :designated_quantity, numericality: { greater_than_or_equal_to: 0 }
  validates :dispatched_quantity, numericality: { greater_than_or_equal_to: 0 }
  validates :received_quantity, numericality: { greater_than: 0 }
  validates :weight, :pieces, numericality: { allow_blank: true, greater_than: 0 }
  validates :width, :height, :length, numericality: { allow_blank: true, greater_than_or_equal_to: 0 }
  validate  :validate_set_id, on: [:create, :update]
  validates_uniqueness_of :inventory_number, if: :should_validate_inventory_number?

  scope :donor_packages, ->(donor_id) { joins(item: [:offer]).where(offers: { created_by_id: donor_id }) }
  scope :received, -> { where(state: 'received') }
  scope :expecting, -> { where(state: 'expecting') }
  scope :inventorized, -> { where.not(inventory_number: nil) }
  scope :published, -> { where(allow_web_publish: true) }
  scope :latest, -> { order('id desc') }
  scope :stockit_items, -> { where.not(stockit_id: nil) }
  scope :except_package, ->(id) { where.not(id: id) }
  scope :undispatched, -> { where(stockit_sent_on: nil) }
  scope :undesignated, -> { where(order_id: nil) }
  scope :not_multi_quantity, -> { where("received_quantity = 1") }
  scope :exclude_designated, ->(designation_id) {
    where("order_id <> ? OR order_id IS NULL", designation_id)
  }

  accepts_nested_attributes_for :packages_locations, :detail, allow_destroy: true, limit: 1

  attr_accessor :skip_set_relation_update, :request_from_admin, :detail_attributes

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
      package.add_to_stockit if STOCKIT_ENABLED
    end

    before_transition on: :mark_missing do |package|
      package.delete_associated_packages_locations
      package.received_at = nil
      package.location_id = nil
      package.allow_web_publish = false
      package.remove_from_stockit
    end
  end

  def assign_stockit_designated_by
    if (stockit_designated_on.presence && order_id.presence)
      self.stockit_designated_by = User.stockit_user
    else
      self.stockit_designated_by = nil
    end
  end

  def assign_stockit_sent_by_and_designated_by
    if stockit_sent_on.presence && stockit_designated_on.presence
      self.stockit_sent_by = User.stockit_user
      self.stockit_designated_by = User.stockit_user
    elsif stockit_sent_on.presence
      self.stockit_sent_by = User.stockit_user
    else
      self.stockit_sent_by = nil
    end
  end

  def quantity_contained_in(container_id)
    PackagesInventory::Computer.quantity_contained_in(package: self, container: Package.find(container_id))
  end

  def dispatch_from_stockit?
    stockit_sent_on_changed? && GoodcitySync.request_from_stockit
  end

  def order_id_nil?
    order_id.nil?
  end

  def stockit_sent_on_present?
    stockit_sent_on.present?
  end

  def same_order_id_as_designation?
    designation.order_id == order_id
  end

  def designation
    orders_packages.designated.first
  end

  def unless_dispatch_and_order_id_changed_with_request_from_stockit?
    !stockit_sent_on_changed? && order_id_changed? && GoodcitySync.request_from_stockit
  end

  def orders_package_with_different_designation
    if (orders_package = orders_packages.get_records_associated_with_order_id(order_id).first)
      (orders_package != designation && orders_package.try(:state) != 'dispatched') && orders_package
    end
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
    !STOCKIT_ENABLED
  end

  def add_to_stockit
    return if box_or_pallet? || (detail.present? && !detail.valid?)

    response = Stockit::ItemSync.create(self)
    if response && (errors = response["errors"]).present?
      errors.each { |key, value| self.errors.add(key, value) }
    elsif response && (item_id = response["item_id"]).present?
      self.stockit_id = item_id
    end
  end

  def remove_from_stockit
    if self.inventory_number.present?
      response = Stockit::ItemSync.delete(inventory_number)
      if response && (errors = response["errors"]).present?
        errors.each { |key, value| self.errors.add(key, value) }
      else
        self.inventory_number = nil
        self.stockit_id = nil
      end
    end
  end

  # Required by PushUpdates and PaperTrail modules
  def offer
    item.try(:offer)
  end

  def updated_received_package?
    !self.previous_changes.key?("state") && received? &&
    !GoodcitySync.request_from_stockit
  end

  def designate_to_stockit_order!(order_id)
    designate_to_stockit_order(order_id)
    save
  end

  def designate_to_stockit_order(order_id)
    self.update(order_id: order_id) if Order.find_by(id: order_id)
    self.stockit_designated_on = Date.today
    self.stockit_designated_by = User.current_user
    self.donor_condition_id =  donor_condition_id.presence || 3
    response = Stockit::ItemSync.update(self)
    add_errors(response)
  end

  def undesignate_from_stockit_order
    self.order = nil
    self.stockit_designated_on = nil
    self.stockit_designated_by = nil
    response = Stockit::ItemSync.update(self)
    add_errors(response)
  end

  # @TODO: remove
  #
  def dispatch_stockit_item(_orders_package = nil, package_location_changes = nil, skip_set_relation_update = false)
    self.skip_set_relation_update = skip_set_relation_update
    self.stockit_sent_on = Date.today
    self.stockit_sent_by = User.current_user
    self.box = nil
    self.pallet = nil
    response = Stockit::ItemSync.dispatch(self)
    add_errors(response)
  end

  def undispatch_stockit_item
    self.stockit_sent_on = nil
    self.stockit_sent_by = nil
    self.pallet = nil
    self.box = nil
    response = Stockit::ItemSync.undispatch(self)
    add_errors(response)
  end

  def has_box_or_pallet_error
    error =
      if pallet_id?
        I18n.t("package.has_pallet_error", pallet_number: pallet.pallet_number)
      else
        I18n.t("package.has_box_error", box_number: box.box_number)
      end
    {
      "errors" => {
        error: "#{error} #{I18n.t('package.move_stockit')}"
      }
    }
  end

  def add_errors(response)
    if response && (errors = response["errors"]).present?
      errors.each { |key, value| self.errors.add(key, value) }
    end
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

  def inventory_package_set
    item.packages.inventorized.undispatched
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
      images.update_all(favourite: false)
      current_image.update_column(:favourite, true)
      self.favourite_image_id = current_image.id
    end
  end

  def singleton_package?
    received_quantity == 1
  end

  def stockit_order_id
    if (orders_packages = OrdersPackage.get_designated_and_dispatched_packages(id)).exists?
      orders_packages.first.order.try(:stockit_id)
    end
  end

  def donor_condition_name
    donor_condition.try(:name_en) || item.try(:donor_condition).try(:name_en)
  end

  def storage_type_name
    storage_type&.name
  end

  def box?
    storage_type_name&.eql?("Box")
  end

  def box_or_pallet?
    %w[Box Pallet].include?(storage_type_name)
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
    self.saleable ||= offer.try(:saleable)
    true
  end

  def delete_item_from_stockit
    StockitDeleteJob.perform_later(self.inventory_number)
    remove_inventory_number
  end

  def update_stockit_item
    StockitUpdateJob.perform_later(id)
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
end
