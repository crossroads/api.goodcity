class PackUnpack
  def initialize(container, package, location_id, quantity, user_id)
    @cause = container # box or pallet
    @package = package # item to add or remove
    @location_id = location_id
    @quantity = quantity # quantity to pack or unpack
    @user_id = user_id
  end

  def pack
    return error(I18n.t("box_pallet.errors.adding_box_to_box")) if adding_box_to_a_box?
    return error(I18n.t("box_pallet.errors.item_designated")) if item_designated?
    return error(I18n.t("box_pallet.errors.invalid_quantity")) if invalid_quantity?
    pkg_inventory = pack_or_unpack(PackagesInventory::Actions::PACK)
    response(pkg_inventory)
  end

  def unpack
    pkg_inventory = pack_or_unpack(PackagesInventory::Actions::UNPACK)
    response(pkg_inventory)
  end

  private

  def self.action_allowed?(task)
    GoodcitySetting.enabled?("stock.allow_box_pallet_item_addition") &&
    PACK_UNPACK_ALLOWED_ACTIONS.include?(task)
  end

  def pack_or_unpack(task)
    return unless @quantity.positive?
    PackagesInventory.new(
      package: @package,
      source: @cause,
      action: task,
      location_id: @location_id,
      user_id: @user_id,
      quantity: quantity(task)
    )
  end

  def quantity(task)
    task.eql?("pack") ? @quantity * -1 : @quantity
  end

  def error(error)
    { errors: [error], success: false }
  end

  def response(pkg_inventory)
    return unless pkg_inventory
    if pkg_inventory.save
      { packages_inventory: pkg_inventory, success: true }
    elsif pkg_inventory.errors
      error(pkg_inventory.errors.full_messages)
    end
  end

  def invalid_quantity?
    @quantity > PackagesLocation.available_quantity_at_location(@location_id, @package.id)
  end

  # def available_quantity_on_location(location_id)
  #   PackagesLocation.where(location_id: location_id, package_id: @package.id).first.quantity
  # end

  def adding_box_to_a_box?
    @package.box? && @cause.box?
  end

  def item_designated?
    @package.order.presence
  end
end
