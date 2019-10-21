class PackagesInventory < ActiveRecord::Base
  module Actions
    INVENTORY = 'inventory'
    LOSS      = 'loss'
    GAIN      = 'gain'
    DISPATCH  = 'dispatch'
  end

  ALLOWED_ACTIONS = [
    Actions::INVENTORY,
    Actions::LOSS,
    Actions::DISPATCH,
    Actions::GAIN
  ].freeze

  include AppendOnly
  include InventoryComputer

  belongs_to :package
  belongs_to :location
  belongs_to :user
  belongs_to :source, polymorphic: true, touch: true

  # --- Validations
  validate :valid_action, on: [:create, :update]

  def valid_action
    return if ALLOWED_ACTIONS.include?(action)
    errors.add(:errors, I18n.t('package_inventory.bad_action'))
  end

end
