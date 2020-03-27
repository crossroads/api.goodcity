class PackagesInventory < ActiveRecord::Base
  module Actions
    INVENTORY   = 'inventory'.freeze
    UNINVENTORY = "uninventory".freeze
    LOSS        = 'loss'.freeze
    GAIN        = 'gain'.freeze
    DISPATCH    = 'dispatch'.freeze
    UNDISPATCH  = 'undispatch'.freeze
    MOVE        = 'move'.freeze
    PACK        = "pack".freeze
    UNPACK      = "unpack".freeze
    TRASH       = "trash".freeze
    UNTRASH     = "untrash".freeze
    PROCESS     = "process".freeze
    UNPROCESS   = "unprocess".freeze
    RECYCLE     = "recycle".freeze
    PRESERVE    = "preserve".freeze
  end

  INCREMENTAL_ACTIONS = [Actions::INVENTORY, Actions::UNDISPATCH, Actions::GAIN, Actions::UNPACK,
    Actions::UNTRASH, Actions::UNPROCESS, Actions::PRESERVE].freeze
  DECREMENTAL_ACTIONS = [Actions::UNINVENTORY, Actions::LOSS, Actions::DISPATCH, Actions::PACK,
    Actions::TRASH, Actions::PROCESS, Actions::RECYCLE].freeze
  QUANTITY_LOSS_ACTIONS = [Actions::LOSS, Actions::TRASH, Actions::PROCESS, Actions::RECYCLE].freeze
  QUANTITY_GAIN_ACTIONS = [Actions::GAIN].freeze
  UNRESTRICTED_ACTIONS = [Actions::MOVE].freeze
  ALLOWED_ACTIONS = (INCREMENTAL_ACTIONS + DECREMENTAL_ACTIONS + UNRESTRICTED_ACTIONS).freeze

  include EventEmitter
  include AppendOnly
  include HookControls
  include Secured
  include InventoryLegacySupport
  include InventoryComputer

  belongs_to :package, touch: true
  belongs_to :location
  belongs_to :user
  belongs_to :source, polymorphic: true, touch: true

  after_create { PackagesInventory.emit(self.action, self) }

  # --------------------
  # Undo feature
  # --------------------

  REVERSIBLE_ACTIONS = {
    Actions::INVENTORY    => Actions::UNINVENTORY,
    Actions::DISPATCH     => Actions::UNDISPATCH,
    Actions::GAIN         => Actions::LOSS,
    Actions::UNINVENTORY  => Actions::INVENTORY,
    Actions::PACK         => Actions::UNPACK,
    Actions::UNPACK       => Actions::PACK,
    Actions::UNDISPATCH   => Actions::DISPATCH,
    Actions::LOSS         => Actions::GAIN,
    Actions::TRASH        => Actions::UNTRASH,
    Actions::PROCESS      => Actions::UNPROCESS,
    Actions::RECYCLE      => Actions::PRESERVE
  }.freeze

  def undo
    raise Goodcity::InventoryError.new(I18n.t('packages_inventory.cannot_undo')) unless REVERSIBLE_ACTIONS.key?(action)
    PackagesInventory.secured_transaction(package.id) do
      PackagesInventory.create!({
        action:   REVERSIBLE_ACTIONS[action],
        user:     User.current_user || User.system_user,
        package:  package,
        source:   source,
        location: location,
        quantity: quantity * -1
      })
    end
  end

  # --------------------
  # Helpers
  # --------------------

  def self.inventorized?(package)
    last = PackagesInventory.order('id DESC').where(package: package).limit(1).first
    last.present? && !last.uninventory?
  end

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
      package_id = Utils.to_id(
        params.with_indifferent_access[:package] ||
        params.with_indifferent_access[:package_id]
      )

      PackagesInventory.secured_transaction(package_id) do
        PackagesInventory.create!({
          action: action_name,
          user: User.current_user || User.system_user
        }.merge(params))
      end
    end
  end

  # --------------------
  # Validations
  # --------------------

  validate :validate_fields, on: [:create]

  def validate_action
    # Catch invalid actions
    errors.add(:errors, I18n.t('package_inventory.bad_action', action: action)) unless ALLOWED_ACTIONS.include?(action)

    # Prevent GAIN of boxes and pallets
    # We allow other incremental actions as they only follow up decremennts (e.g dispatch/undispatch)
    errors.add(:errors, I18n.t('package_inventory.bad_action_for_type', type: package.storage_type.name, action: action)) if package.storage_type&.singleton? && action.eql?(Actions::GAIN)
    errors.count.zero?
  end

  def validate_quantity
    return errors.add(:errors, I18n.t('package_inventory.quantities.zero_invalid')) if quantity.zero?
    if incremental?
      outcome_qty = PackagesInventory::Computer.package_quantity(package) + quantity
      maximum_qty = package.storage_type&.capped? ? package.storage_type.max_unit_quantity : Float::INFINITY

      errors.add(:errors, I18n.t('package_inventory.quantities.enforced_positive', action: action)) if quantity.negative?
      errors.add(:errors, I18n.t('package_inventory.storage_type_max', type: package.storage_type.name, quantity: maximum_qty )) if outcome_qty > maximum_qty
    else
      errors.add(:errors, I18n.t('package_inventory.quantities.enforced_negative', action: action)) if quantity.positive?
    end
    errors.count.zero?
  end

  def validate_fields
    validate_action && validate_quantity
  end
end
