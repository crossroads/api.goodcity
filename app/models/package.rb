class Package < ActiveRecord::Base
  has_paper_trail class_name: 'Version', meta: { related: :offer }
  include Paranoid
  include StateMachineScope
  include PushUpdates

  belongs_to :item
  belongs_to :location
  belongs_to :package_type, inverse_of: :packages
  belongs_to :donor_condition
  belongs_to :pallet
  belongs_to :box
  belongs_to :stockit_designation
  belongs_to :stockit_designated_by, class_name: 'User'
  belongs_to :stockit_sent_by, class_name: 'User'

  before_destroy :delete_item_from_stockit, if: :inventory_number
  before_create :set_donor_condition_and_grade
  after_commit :update_stockit_item, on: :update, if: :updated_received_package?

  validates :package_type_id, :quantity, presence: true
  validates :quantity,  numericality: { greater_than: 0, less_than: 100000000 }
  validates :length, numericality: {
    allow_blank: true, greater_than: 0, less_than: 100000000 }
  validates :width, :height, numericality: {
    allow_blank: true, greater_than: 0, less_than: 100000 }

  scope :donor_packages, ->(donor_id) { joins(item: [:offer]).where(offers: {created_by_id: donor_id}) }
  scope :received, -> { where("state = 'received'") }

  scope :latest, -> { order('id desc') }
  scope :stockit_items, -> { where("stockit_id IS NOT NULL") }
  scope :undispatched, -> { where(stockit_sent_on: nil) }
  scope :exclude_designated, ->(designation_id) {
    where("stockit_designation_id <> ? OR stockit_designation_id IS NULL", designation_id)
  }

  def self.search(search_text, item_id)
    if item_id.presence
      where("item_id = ?", item_id)
    else
      where("inventory_number LIKE :query", query: "%#{search_text}%")
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
    self.stockit_designation = StockitDesignation.find_by(id: order_id)
    self.stockit_designated_on = Date.today
    self.stockit_designated_by = User.current_user
    response = Stockit::ItemSync.update(self)
    if response && (errors = response["errors"]).present?
      errors.each{|key, value| self.errors.add(key, value) }
    end
  end

  def undesignate_from_stockit_order
    self.stockit_designation = nil
    self.stockit_designated_on = nil
    self.stockit_designated_by = nil
    response = Stockit::ItemSync.update(self)
    if response && (errors = response["errors"]).present?
      errors.each{|key, value| self.errors.add(key, value) }
    end
  end

  def dispatch_stockit_item
    self.stockit_sent_on = Date.today
    self.stockit_sent_by = User.current_user
    self.box = nil
    self.pallet = nil
    self.location = Location.dispatch_location
    response = Stockit::ItemSync.dispatch(self)
    if response && (errors = response["errors"]).present?
      errors.each{|key, value| self.errors.add(key, value) }
    end
  end

  def undispatch_stockit_item
    self.stockit_sent_on = nil
    self.stockit_sent_by = nil
    self.pallet = nil
    self.box = nil
    response = Stockit::ItemSync.undispatch(self)
    if response && (errors = response["errors"]).present?
      errors.each{|key, value| self.errors.add(key, value) }
    end
  end

  private

  def set_donor_condition_and_grade
    self.donor_condition ||= item.try(:donor_condition)
    self.grade ||= "B"
  end

  def delete_item_from_stockit
    StockitDeleteJob.perform_later(self.inventory_number)
  end

  def update_stockit_item
    StockitUpdateJob.perform_later(id)
  end
end
