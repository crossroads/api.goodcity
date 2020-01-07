class BoxPalletManager
  def initialize(entity, item)
    @entity = entity # box or pallet
    @item = item # item to add or remove
    @action = params[:action] # action pack or unpack
    @user_id = params[:user_id]
    @quantity = params[:quantity] # quantity to pack or unpack
  end

  def run
    pkg_inventory = create_packages_inventory
    if pkg_inventory&.save
      return { packages_inventory: pkg_inventory, success: true }
    elsif pkg_inventory&.errors
      return { errors: pkg_inventory.errors.full_messages, success: false }
    end
  end

  private

  def create_packages_inventory
    return unless @action
    PackagesInventory.new(
      source: @entity,
      acton: @action,
      location_id: @entity.location_id,
      user_id: @user_id,
      quantity: quantity
    )
  end

  def quantity
    qty = @quantity || @item.quantity
    pack_action? ? qty * -1 : qty
  end

  def pack_action?
    @action.eql?("pack")
  end
end
