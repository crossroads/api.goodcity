class PackagesInventory < ActiveRecord::Base
  module Actions
    INVENTORY   = 'inventory'.freeze
    LOSS        = 'loss'.freeze
    GAIN        = 'gain'.freeze
    DISPATCH    = 'dispatch'.freeze
    UNDISPATCH  = 'undispatch'.freeze
    MOVE        = 'move'.freeze
  end

  INCREMENTAL_ACTIONS = [Actions::INVENTORY, Actions::UNDISPATCH, Actions::GAIN].freeze
  DECREMENTAL_ACTIONS = [Actions::LOSS, Actions::DISPATCH].freeze
  UNRESTRICTED_ACTIONS = [Actions::MOVE].freeze
  ALLOWED_ACTIONS = (INCREMENTAL_ACTIONS + DECREMENTAL_ACTIONS + UNRESTRICTED_ACTIONS).freeze

  include AppendOnly
  include HookControls
  include Secured
  include InventoryLegacySupport
  include InventoryComputer

  belongs_to :package
  belongs_to :location
  belongs_to :user
  belongs_to :source, polymorphic: true, touch: true

  # --- Helpers

  def incremental?
    return quantity.positive? if UNRESTRICTED_ACTIONS.include?(action)
    INCREMENTAL_ACTIONS.include?(action)
  end

  def decremental?
    return quantity.negative? if UNRESTRICTED_ACTIONS.include?(action)
    DECREMENTAL_ACTIONS.include?(action)
  end

  ALLOWED_ACTIONS.each do |action_name|
    # Generate dispatch?, gain?, loss?, etc
    define_method "#{action_name}?"  do
      action.eql?(action_name)
    end

    # Generate append_gain, append_dispatch, etc
    define_singleton_method "append_#{action_name}"  do |params|
      PackagesInventory.create({
        action: action_name,
        user: User.current_user || User.system_user
      }.merge(params))
    end
  end

  # --- Validations
  validate :validate_fields, on: [:create]

  def validate_action
    return if ALLOWED_ACTIONS.include?(action)
    errors.add(:errors, I18n.t('package_inventory.bad_action', action: action) )
  end

  def validate_quantity
    return errors.add(:errors, I18n.t('package_inventory.quantities.zero_invalid')) if quantity.zero?
    if incremental?
      errors.add(:errors, I18n.t('package_inventory.quantities.enforced_positive', action: action)) if quantity.negative?
    else
      errors.add(:errors, I18n.t('package_inventory.quantities.enforced_negative', action: action)) if quantity.positive?
    end
  end

  def validate_fields
    validate_action
    validate_quantity
  end
end
