class BoxPalletManager
  attr_accessor :entity, :item, :action, :user_id

  def initialize(params, user_id)
    @entity = Package.find(params[:id]) # box or pallet
    @item = Package.find(params[:item_id]) # item to add or remove
    @action = params[:task] # action pack or unpack
    @user_id = user_id
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
    return unless action
    PackagesInventory.new(
      package: item,
      source: entity,
      action: action,
      location_id: entity.location_id,
      user_id: user_id,
      quantity: quantity
    )
  end

  def quantity
    qty = @quantity || item.quantity
    pack_action? ? qty * -1 : qty
  end

  def pack_action?
    action.eql?("pack")
  end
end
