class Stocktake < ApplicationRecord
  include Watcher
  include StocktakeProcessor
  include PushUpdatesMinimal
  include Secured

  has_many    :stocktake_revisions, dependent: :destroy
  belongs_to  :location
  belongs_to  :created_by, class_name: "User"

  alias_attribute :revisions, :stocktake_revisions

  # ---------------------
  # Live updates
  # ---------------------

  after_commit :push_changes
  push_targets [ Channel::STOCK_MANAGEMENT_CHANNEL ]

  # ---------------------
  # States
  # ---------------------

  state_machine :state, initial: :open do
    state :open, :awaiting_process, :processing, :closed, :cancelled

    event :reopen do
      transition all => :open
    end

    event :mark_for_processing do
      transition [:open] => :awaiting_process
    end

    event :start_processing do
      transition [:open, :awaiting_process] => :processing
    end

    event :close do
      transition [:open, :processing, :awaiting_process] => :closed
    end

    event :cancel do
      transition all - [:closed] => :cancelled
    end

    after_transition on: :cancel do |stocktake|
      StocktakeRevision.where(stocktake: stocktake).update_all(state: 'cancelled')
    end
  end

  # ---------------------
  # Computed Properties
  # ---------------------

  watch [StocktakeRevision] do |rev|
    rev.stocktake.compute_counters! if rev.stocktake.open? && !Stocktake.disable_auto_counters?
  end

  # ---------------------
  # Methdos
  # ---------------------

  #
  # Creates revisions for every package of the stocktake's location
  #
  # @return [Array<StocktakeRevision>] The newly created revisions
  #
  def populate_revisions!
    attrs = {
      created_by_id: User.current_user&.id || User.system_user.id,
      state: "'pending'",
      dirty: true,
      stocktake_id: id,
      quantity: 0,
    }

    keys = ActiveRecord::Base.sanitize_sql(attrs.keys.join(','))
    values = ActiveRecord::Base.sanitize_sql(attrs.values.join(','))

    ActiveRecord::Base.connection.execute <<-SQL
      INSERT INTO stocktake_revisions (package_id, created_at, updated_at, #{keys})
        SELECT pinv.package_id, NOW(), NOW(), #{values}
        FROM packages_inventories AS pinv
        WHERE location_id = #{location_id} AND package_id NOT IN (
          SELECT package_id FROM stocktake_revisions WHERE stocktake_id = #{id}
        )
        GROUP BY package_id
        HAVING SUM(quantity) > 0
    SQL

    compute_counters!
  end

  def clear_counters!
    self.counts = 0
    self.gains = 0
    self.losses = 0
    self.warnings = 0
  end

  def self.disable_auto_counters=(disabled)
    Thread.current[:stocktake_auto_counters_disabled] = disabled
  end

  def self.disable_auto_counters?
    Thread.current[:stocktake_auto_counters_disabled].eql?(true)
  end

  def self.without_auto_counters
    self.disable_auto_counters = true
    yield
  ensure
    self.disable_auto_counters = false
  end

  def compute_counters!
    clear_counters!

    StocktakeRevision.where(stocktake_id: id).each do |rev|
      if rev.dirty
        self.warnings += 1
      else
        delta = rev.computed_diff
        self.losses += 1    if delta < 0
        self.gains  += 1    if delta > 0
        self.warnings += 1  if rev.warning.present?
        self.counts += 1
      end
    end
    self.save!
  end
end
