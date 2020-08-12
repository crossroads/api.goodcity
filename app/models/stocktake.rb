class Stocktake < ApplicationRecord
  include StocktakeProcessor
  include PushUpdatesMinimal

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
    state :open, :closed, :cancelled

    event :reopen do
      transition [:closed, :cancelled] => :open
    end

    event :close do
      transition open: :closed
    end

    event :cancel do
      transition all - [:closed] => :cancelled
    end

    after_transition on: :cancel do |stocktake|
      StocktakeRevision.where(stocktake: stocktake).update_all(state: 'cancelled')
    end
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
    package_ids = PackagesInventory
      .where(location_id: location_id)
      .group(:package_id)
      .having('SUM(quantity) > 0')
      .pluck(:package_id)

    ActiveRecord::Base.transaction do
      package_ids.map do |pid|
        StocktakeRevision.find_or_create_by(package_id: pid, stocktake_id: id) do |revision|
          revision.quantity       = 0
          revision.dirty          = true
          revision.state          = 'pending'
          revision.created_by_id  = User.current_user&.id || User.system_user.id
        end
      end
    end
  end
end
