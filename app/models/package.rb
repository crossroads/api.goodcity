class Package < ActiveRecord::Base
  has_paper_trail class_name: 'Version', meta: { related: :offer }
  include Paranoid
  include StateMachineScope
  include PushUpdates

  belongs_to :item
  belongs_to :location
  belongs_to :package_type, inverse_of: :packages

  before_destroy :delete_item_from_stockit, if: :inventory_number
  after_commit :update_stockit_item, on: :update, if: :updated_received_package?

  validates :package_type_id, :quantity, presence: true
  validates :quantity,  numericality: { greater_than: 0, less_than: 100000000 }
  validates :length, numericality: {
    allow_blank: true, greater_than: 0, less_than: 100000000 }
  validates :width, :height, numericality: {
    allow_blank: true, greater_than: 0, less_than: 100000 }

  scope :donor_packages, ->(donor_id) { joins(item: [:offer]).where(offers: {created_by_id: donor_id}) }
  scope :received, -> { where("state = 'received'") }

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
    response = Stockit::Item.create(self)
    if response && (errors = response["errors"]).present?
      errors.each{|key, value| self.errors.add(key, value) }
    end
  end

  def remove_from_stockit
    if self.inventory_number.present?
      response = Stockit::Item.delete(self)
      if response && (errors = response["errors"]).present?
        errors.each{|key, value| self.errors.add(key, value) }
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

  private

  def delete_item_from_stockit
    StockitDeleteJob.perform_later(self.inventory_number)
  end

  def update_stockit_item
    StockitUpdateJob.perform_later(id)
  end
end
