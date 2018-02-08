class Ability
  include CanCan::Ability

  attr_accessor :user, :user_id, :admin, :supervisor, :reviewer, :user_offer_ids, :user_permissions

  def initialize(user)
    if user.present?
      @user = user
      @user_id = user.id
      @reviwer = user.reviewer?
      @user_permissions = user.permissions.pluck(:name)
    end
  end

  def can_manage_packages?
    user_permissions.include?('can_manage_packages')
  end

  def can_manage_offers?
    user_permissions.include?('can_manage_offers')
  end

  def package_abilities
    if can_manage_packages?
      can [:index, :show, :create, :update, :destroy, :print_barcode,
        :search_stockit_items, :designate_stockit_item, :remove_from_set,
        :undesignate_stockit_item, :designate_partial_item, :update_partial_quantity_of_same_designation,
        :undesignate_partial_item, :dispatch_stockit_item, :move_stockit_item,
        :move_partial_quantity, :move_full_quantity, :print_inventory_label,
        :undispatch_stockit_item, :stockit_item_details], Package
    end
  end
end
