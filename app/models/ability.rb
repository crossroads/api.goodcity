class Ability
  include CanCan::Ability

  attr_accessor :user, :user_id, :admin, :supervisor, :reviewer, :user_offer_ids, :user_permissions

  def initialize(user)
    public_ability
    if user.present?
      @user = user
      @user_id = user.id
      @reviwer = user.reviewer?
      @user_permissions = user.permissions.pluck(:name)
      define_abilities
    end
  end

  def define_abilities
    package_abilities
    offer_abilities
    deliveries_abilities
    order_abilities
    order_transport_abilities
    holiday_abilities
    organisations_abilities
    user_abilities
    taxonomies
    stockit_abilities
  end

  def can_manage_packages?
    user_permissions.include?('can_manage_packages')
  end

  def can_manage_offers?
    user_permissions.include?('can_manage_offers')
  end

  def can_manage_deliveries?
    user_permissions.include?('can_manage_deliveries')
  end

  def can_manage_orders?
    user_permissions.include?('can_manage_orders')
  end

  def can_manage_order_transport?
    user_permissions.include?('can_manage_order_transport')
  end

  def can_manage_holidays?
    user_permissions.include?('can_manage_holidays')
  end

  def can_check_organisations?
    user_permissions.include?('can_check_organisations')
  end

  def can_manage_packages_locations?
    user_permissions.include?('can_manage_packages_locations')
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

  def offer_abilities
    if can_manage_offers?
      can [:create, :index, :show, :update, :complete_review, :close_offer,
        :finished, :destroy, :review, :mark_inactive, :merge_offer, :receive_offer], Offer
    end
  end

  def deliveries_abilities
    if can_manage_deliveries?
      can [:index, :show, :update, :destroy, :confirm_delivery], Delivery
    end
  end

  def order_abilities
    if can_manage_orders?
      can [:create, :index, :show, :update], Order
    end
  end

  def order_transport_abilities
    if can_manage_order_transport?
      can [:create, :index, :show], OrderTransport
    end
  end

  def holiday_abilities
    if can_manage_holidays?
      can [:index, :destroy, :create, :update], Holiday
    end
  end

  def organisations_abilities
    if can_check_organisations?
      can [:index, :search, :show], Organisation
    end
  end

  def user_abilities
    can :current_user_profile, User
  end

  def taxonomies
    can :register, :device
    can [:index, :show], DonorCondition
    can [:index, :show], SubpackageType
    can [:index, :show], RejectionReason
    can [:index, :show], Permission
    can [:index, :show], CancellationReason
    # can :create, PackageType if @api_user || staff?
    # can [:create, :remove_number], InventoryNumber if api_user_or_staff?
  end

  def public_ability
    can :show_driver_details, Offer, { state: "scheduled", delivery: {gogovan_order: { status: ['pending', 'active'] } } }

    # Anonymous and all users
    can [:index, :show], PackageCategory
    can [:index, :show], PackageType
    can [:fetch_packages], Package # for BrowseController
    can :index, DonorCondition
    can [:index, :show], District
    can [:index, :show], Territory
    can :index, Timeslot
    can :index, GogovanTransport
    can :index, CrossroadsTransport
  end

  def packages_locations_abilities
    if can_manage_packages_locations?
      can [:index, :show], PackagesLocation
    end
  end

  def stockit_abilities
    can [:index, :create, :destroy], Location
  end
end
