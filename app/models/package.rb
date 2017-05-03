class Package < ActiveRecord::Base
  has_paper_trail class_name: 'Version', meta: { related: :offer }
  include Paranoid
  include StateMachineScope
  include PushUpdates

  BROWSE_ITEM_STATES = ['accepted', 'submitted']
  BROWSE_OFFER_EXCLUDE_STATE = ['cancelled', 'inactive', 'closed', 'draft']

  belongs_to :item
  belongs_to :set_item, class_name: 'Item'
  has_many :locations, through: :packages_locations

  belongs_to :package_type, inverse_of: :packages
  belongs_to :donor_condition
  belongs_to :pallet
  belongs_to :box
  belongs_to :order
  belongs_to :stockit_designated_by, class_name: 'User'
  belongs_to :stockit_sent_by, class_name: 'User'
  belongs_to :stockit_moved_by, class_name: 'User'

  has_many   :packages_locations, inverse_of: :package
  has_many   :images, as: :imageable, dependent: :destroy
  has_many   :orders_packages, dependent: :destroy

  before_destroy :delete_item_from_stockit, if: :inventory_number
  before_create :set_default_values
  after_commit :update_stockit_item, on: :update, if: :updated_received_package?
  before_save :save_inventory_number, if: :inventory_number_changed?
  before_save :update_set_relation, if: :stockit_sent_on_changed?
  after_update :update_packages_location_quantity, if: :received_quantity_changed_and_locations_exists?
  after_commit :update_set_item_id, on: :destroy
  after_save :create_or_update_singleton_orders_package, if: :order_id_changed_and_request_from_stockit?
  after_save :dispatch_orders_package, if: :dispatch_from_stockit?

  after_touch { update_client_store :update }

  validates :package_type_id, :quantity, presence: true
  validates :quantity,  numericality: { greater_than_or_equal_to: 0 }
  validates :received_quantity,  numericality: { greater_than: 0, less_than: 100000000 }
  validates :length, numericality: {
    allow_blank: true, greater_than: 0, less_than: 100000000 }
  validates :width, :height, numericality: {
    allow_blank: true, greater_than: 0, less_than: 100000 }

  scope :donor_packages, ->(donor_id) { joins(item: [:offer]).where(offers: {created_by_id: donor_id}) }
  scope :received, -> { where(state: 'received') }
  scope :expecting, -> { where(state: 'expecting') }
  scope :inventorized, -> { where.not(inventory_number: nil) }
  scope :published, -> { where(allow_web_publish: true) }
  scope :non_set_items, -> { where(set_item_id: nil) }
  scope :set_items, -> { where("set_item_id = item_id") }
  scope :latest, -> { order('id desc') }
  scope :stockit_items, -> { where.not(stockit_id: nil) }
  scope :except_package, ->(id) { where.not(id: id) }
  scope :undispatched, -> { where(stockit_sent_on: nil) }
  scope :undesignated, -> { where(order_id: nil) }
  scope :exclude_designated, ->(designation_id) {
    where("order_id <> ? OR order_id IS NULL", designation_id)
  }

  accepts_nested_attributes_for :packages_locations, allow_destroy: true, limit: 1

  attr_accessor :skip_set_relation_update

  def self.search(search_text, item_id)
    if item_id.presence
      where("item_id = ? and received_quantity = 1", item_id)
    else
      where("inventory_number ILIKE :query and received_quantity = 1", query: "%#{search_text}%")
    end
  end

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
      package.add_to_stockit
    end

    after_transition on: [:mark_received, :mark_missing] do |package|
      package.update_set_item_id
    end

    before_transition on: :mark_missing do |package|
      package.delete_associated_packages_locations
      package.received_at = nil
      package.remove_from_stockit
    end
  end

  def received_quantity_changed_and_locations_exists?
    received_quantity_changed? && locations.exists?
  end

  def update_packages_location_quantity
    packages_locations.first.update_quantity(received_quantity)
  end

  def dispatch_from_stockit?
    stockit_sent_on_changed? && GoodcitySync.request_from_stockit
  end

  def build_or_create_packages_location(location_id, operation)
    if GoodcitySync.request_from_stockit && is_singleton_package? && self.packages_locations.exists?
      packages_locations.first.update_column(:location_id, location_id)
    elsif (packages_location = packages_locations.find_by(location_id: location_id))
      packages_location.update_quantity(received_quantity)
    else
      packages_locations.send(operation, {
        location_id: location_id,
        quantity: received_quantity
      })
    end
  end

  def is_order_id_nil?
    order_id.nil?
  end

  def dispatch_oredrs_pacakge
    designation = orders_packages.designated.first
    if is_singleton_package? && (orders_package = orders_package_with_different_designation(designation))
      cancel_designation(designation)
      orders_package.dispatch!
    elsif is_singletone_and_has_designation?(designation) && stockit_sent_on.present?
      designation.dispatch
    elsif !stockit_sent_on.nil?
      orders_packages.create(
        order_id: order_id,
        quantity: quantity,
        state: 'dispatched',
        sent_on: Time.now
      )
    end
  end

  def create_or_update_singleton_orders_package
    designation = orders_packages.designated.first
    if is_singleton_package? && (orders_package = orders_package_with_different_designation(designation))
      cancel_designation(designation)
      orders_package.update(state: 'designated', quantity: quantity)
    elsif is_singletone_and_has_designation?(designation) && is_order_id_nil?
      cancel_designation(designation)
    elsif is_singletone_and_has_designation?(designation)
      designation.update_designation(order_id)
    elsif !is_order_id_nil?
      OrdersPackage.add_partially_designated_item(
        order_id: order_id,
        package_id: id,
        quantity: quantity
      )
    end
    update_in_stock_quantity
  end

  def cancel_designation(designation)
    designation and designation.cancel!
  end

  def order_id_changed_and_request_from_stockit?
    order_id_changed? && GoodcitySync.request_from_stockit
  end

  def orders_package_with_different_designation(designation)
    orders_package = orders_packages.get_records_associated_with_order_id(order_id).first
    unless(orders_package and (orders_package == designation && orders_package.try(:state) == 'dispatched'))
      orders_package
    end
  end

  def is_singletone_and_has_designation?(designation)
    is_singleton_package? && designation
  end

  def delete_associated_packages_locations
    packages_locations.destroy_all
  end

  def update_allow_web_publish_to_false
    update(allow_web_publish: false)
  end

  def add_to_stockit
    response = Stockit::ItemSync.create(self)
    if response && (errors = response["errors"]).present?
      errors.each{|key, value| self.errors.add(key, value) }
    elsif response && (item_id = response["item_id"]).present?
      self.stockit_id = item_id
    end
  end

  def stockit_location_id
    if packages_locations.count > 1
      Location.multiple_location.try(:stockit_id)
    else
      packages_locations.first.try(:location).try(:stockit_id) || Location.find_by(id: location_id).try(:stockit_id)
    end
  end

  def remove_from_stockit
    if self.inventory_number.present?
      response = Stockit::ItemSync.delete(inventory_number)
      if response && (errors = response["errors"]).present?
        errors.each{|key, value| self.errors.add(key, value) }
      else
        self.inventory_number = nil
        self.stockit_id = nil
        self.set_item_id = nil
      end
    end
  end

  # Required by PushUpdates and PaperTrail modules
  def offer
    item.try(:offer)
  end

  def updated_received_package?
    !self.previous_changes.has_key?("state") && received? &&
    !GoodcitySync.request_from_stockit
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

  def update_set_relation
    if set_item_id.present? && stockit_sent_on.present? && !skip_set_relation_update
      self.set_item_id = nil
      update_set_item_id(inventory_package_set.except_package(id))
    end
  end

  def dispatch_stockit_item(_orders_package=nil, package_location_changes=nil , skip_set_relation_update=false)
    self.skip_set_relation_update = skip_set_relation_update
    self.stockit_sent_on = Date.today
    self.stockit_sent_by = User.current_user
    self.box = nil
    self.pallet = nil
    deduct_dispatch_quantity(package_location_changes) if package_location_changes
    response = Stockit::ItemSync.dispatch(self)
    add_errors(response)
  end

  def deduct_dispatch_quantity(package_qty_changes)
    package_qty_changes.each_pair do |_key, pckg_qty_param|
      update_existing_package_location_qty(pckg_qty_param["packages_location_id"], pckg_qty_param["qty_to_deduct"])
    end
  end

  def undispatch_stockit_item
    self.stockit_sent_on = nil
    self.stockit_sent_by = nil
    self.pallet = nil
    self.box = nil
    response = Stockit::ItemSync.undispatch(self)
    add_errors(response)
  end

  def move_partial_quantity(location_id, package_qty_changes, total_qty)
    package_qty_changes.each do |pckg_qty_param|
      update_existing_package_location_qty(pckg_qty_param["packages_location_id"],  pckg_qty_param["new_qty"])
    end
    update_or_create_qty_moved_to_location(location_id, total_qty)
  end

  def move_full_quantity(location_id, orders_package_id)
    orders_package              = orders_packages.find_by(id: orders_package_id)
    referenced_package_location = packages_locations.find_by(reference_to_orders_package: orders_package_id)

    if(packages_location_record = find_packages_location_with_location_id(location_id))
      new_qty = orders_package.quantity + packages_location_record.quantity
      packages_location_record.update(quantity: new_qty, reference_to_orders_package: nil)
      referenced_package_location.destroy
    else
      referenced_package_location.update(location_id: location_id, quantity: orders_package.quantity,
        reference_to_orders_package: nil)
    end
  end

  def find_packages_location_with_location_id(location_id)
    packages_locations.find_by(location_id: location_id)
  end

  def update_or_create_qty_moved_to_location(location_id, total_qty)
    if(packages_location = find_packages_location_with_location_id(location_id))
      packages_location.update(quantity: packages_location.quantity + total_qty.to_i)
    else
      packages_locations.create(location_id: location_id, package_id: id, quantity: total_qty)
    end
  end

  def update_existing_package_location_qty(packages_location_id, quantity_to_move)
    if(packages_location = packages_locations.find_by(id: packages_location_id))
      new_qty = packages_location.quantity - quantity_to_move.to_i
      new_qty == 0 ? packages_location.destroy : packages_location.update_column(:quantity, new_qty)
    end
  end

  def move_stockit_item(location_id)
    response = if box_id? || pallet_id?
      has_box_or_pallet_error
    else
      build_or_create_packages_location(location_id, 'create')
      self.stockit_moved_on = Date.today
      self.stockit_moved_by = User.current_user
      Stockit::ItemSync.move(self)
    end
    add_errors(response)
  end

  def has_box_or_pallet_error
    error = if pallet_id?
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
      errors.each{|key, value| self.errors.add(key, value) }
    end
  end

  def update_set_item_id(all_packages = nil)
    if item
      all_packages ||= inventory_package_set
      if all_packages.length == 1
        all_packages.update_all(set_item_id: nil)
      else
        all_packages.non_set_items.update_all(set_item_id: item.id)
      end
    end
  end

  def remove_from_set
    update(set_item_id: nil)
    update_set_item_id(inventory_package_set.except_package(id))
  end

  def update_designation(order_id)
    update(order_id: order_id)
  end

  def remove_designation
    update(order_id: nil)
  end

  def update_in_stock_quantity
    if GoodcitySync.request_from_stockit
      update_column(:quantity, in_hand_quantity)
    else
      update(quantity: in_hand_quantity)
    end
  end

  def in_hand_quantity
    received_quantity - total_assigned_quantity
  end

  def total_assigned_quantity
    total_quantity = 0
    if(associated_orders_packages = orders_packages.get_designated_and_dispatched_packages(id).presence)
      associated_orders_packages.each do |orders_package|
        total_quantity += orders_package.quantity
      end
    end
    total_quantity
  end

  def inventory_package_set
    item.packages.inventorized.undispatched
  end

  def self.browse_inventorized
    inventorized.published
  end

  def self.browse_non_inventorized
    joins(item: [:offer]).published.expecting.
      where(items: { state: BROWSE_ITEM_STATES }).
      where.not(offers: {state: BROWSE_OFFER_EXCLUDE_STATE})
  end

  def update_favourite_image(image_id)
    image = images.find_by(id: image_id)
    image.update(favourite: true)
    image.imageable.images.where.not(id: image_id).update_all(favourite: false)
  end

  def is_singleton_package?
    received_quantity == 1
  end

  def update_location_quantity(total_quantity, location_id)
    packages_locations.where(location_id: location_id).first.update_column(:quantity, total_quantity)
  end

  def destroy_other_locations(location_id)
    packages_locations.exclude_location(location_id).destroy_all
  end

  def stockit_order_id
    if(orders_packages = OrdersPackage.get_designated_and_dispatched_packages(id)).exists?
      orders_packages.first.order.try(:stockit_id)
    end
  end

  private

  def set_default_values
    self.donor_condition ||= item.try(:donor_condition)
    self.grade ||= "B"
    self.saleable = offer.try(:saleable) || false
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

