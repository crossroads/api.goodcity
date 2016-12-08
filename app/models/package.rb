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

  has_many   :packages_locations
  has_many   :images, as: :imageable, dependent: :destroy
  has_many :orders_packages

  before_destroy :delete_item_from_stockit, if: :inventory_number
  before_create :set_default_values
  after_commit :update_stockit_item, on: :update, if: :updated_received_package?
  before_save :save_inventory_number, if: :inventory_number_changed?
  before_save :update_set_relation, if: :stockit_sent_on_changed?
  after_commit :update_set_item_id, on: :destroy
  after_touch { update_client_store :update }

  validates :package_type_id, :quantity, presence: true
  validates :quantity,  numericality: { greater_than: -1, less_than: 100000000 }
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

  attr_accessor :skip_set_relation_update

  def self.search(search_text, item_id)
    if item_id.presence
      where("item_id = ?", item_id)
    else
      where("inventory_number ILIKE :query", query: "%#{search_text}%")
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
      package.received_at = nil
      package.remove_from_stockit
    end
  end

  def add_to_stockit
    response = Stockit::ItemSync.create(self)
    if response && (errors = response["errors"]).present?
      errors.each{|key, value| self.errors.add(key, value) }
    else response && (item_id = response["item_id"]).present?
      self.stockit_id = item_id
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

  def dispatch_stockit_item(skip_set_relation_update=false)
    self.skip_set_relation_update = skip_set_relation_update
    self.stockit_sent_on = Date.today
    self.stockit_sent_by = User.current_user
    self.box = nil
    self.pallet = nil
    self.locations << Location.dispatch_location
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

  def move_stockit_item(location_id)
    response = if box_id? || pallet_id?
      has_box_or_pallet_error
    else
      self.location_id = location_id
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

  def update_in_stock_quantity(qty)
    in_hand_quantity = received_quantity - qty
    update(quantity: in_hand_quantity)
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
