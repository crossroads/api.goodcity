class StocktakeRevision < ActiveRecord::Base
  include Watcher
  include PushUpdatesMinimal

  belongs_to :stocktake
  belongs_to :package
  belongs_to :created_by, class_name: "User"

  before_save :unset_dirty_and_warning

  # ---------------------
  # Live updates
  # ---------------------

  after_commit :push_changes
  push_targets [ Channel::STOCK_MANAGEMENT_CHANNEL ]

  # ---------------------
  # Validations
  # ---------------------

  attr_readonly :package_id
  attr_readonly :stocktake_id

  validates :quantity, numericality: { greater_than_or_equal_to: 0 }

  # ---------------------
  # Computed properties
  # ---------------------

  watch [PackagesInventory] do |packages_inventory|
    #
    # The stocktake count is invalidated if someone performs a quantity action on the package
    #  
    location = packages_inventory.location
    StocktakeRevision
      .joins(:stocktake)
      .where('stocktakes.location_id = (?)', location.id)
      .where(
        state: 'pending',
        package_id: packages_inventory.package_id
      )
      .update_all(dirty: true)
  end


  # ---------------------
  # Hook methods
  # ---------------------

  def unset_dirty_and_warning
    self.dirty = false unless self.dirty_changed?
    self.warning = '' if self.quantity_changed? && !self.warning_changed?
    true
  end

  # ---------------------
  # States
  # ---------------------

  state_machine :state, initial: :pending do
    state :pending, :processed, :cancelled

    event :process do
      transition pending: :processed
    end

    event :cancel do
      transition pending: :cancelled
    end
  end
end
