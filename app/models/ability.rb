class Ability
  include CanCan::Ability

  # Actions :index, :show, :create, :update, :destroy, :manage
  # See the wiki for details: https://github.com/CanCanCommunity/cancancan/wiki/Defining-Abilities

  attr_accessor :user, :user_id, :admin, :supervisor, :reviewer, :user_offer_ids

  def initialize(user)
    public_ability

    if user.present?

      @user = user
      @user_id = user.id
      @admin = user.admin?
      @supervisor = user.supervisor?
      @reviewer = user.reviewer?
      @api_user = user.api_user?
      @user_offer_ids = user.offers.pluck(:id)

      can(:manage, :all) if admin

      address_abilities
      contact_abilities
      delivery_abilities
      gogovan_order_abilities
      holiday_abilities
      item_abilities
      image_abilities
      message_abilities
      orders_package_abilities
      offer_abilities
      package_abilities
      stockit_abilities
      schedule_abilities
      order_abilities
      order_transport_abilities
      stockit_organisation_abilities
      stockit_contact_abilities
      stockit_local_order_abilities
      taxonomies
      user_abilities
      version_abilities
    end
  end

  def stockit_abilities
    can [:index, :create, :destroy], Location if @api_user || staff?
    can [:create, :index], Box if @api_user
    can [:create, :index], Pallet if @api_user
    can [:create, :index], Country if @api_user
    can [:create, :index], StockitActivity if @api_user
  end

  def delivery_abilities
    can [:create], Delivery
    if staff?
      can [:index, :show, :update, :destroy, :confirm_delivery], Delivery
    else
      can [:show, :update, :destroy, :confirm_delivery], Delivery, offer_id: @user_offer_ids
    end
  end

  def order_abilities
    can :create, Order
    can [:index, :show, :update], Order, created_by_id: @user_id
    can [:create, :index, :show, :update], Order if @api_user || staff?
  end

  def order_transport_abilities
    can :create, OrderTransport
    can [:index, :show], OrderTransport, OrderTransport.user_orders(user_id) do |transport|
        transport.order.created_by_id == @user_id
      end
    can [:create, :index, :show], OrderTransport if staff?
  end

  def stockit_organisation_abilities
    can [:create, :index], StockitOrganisation if @api_user
  end

  def stockit_contact_abilities
    can [:create, :index], StockitContact if @api_user
  end

  def stockit_local_order_abilities
    can [:create, :index], StockitLocalOrder if @api_user
  end

  def holiday_abilities
    can [:available_dates], Holiday
    can [:index, :destroy, :create, :update], Holiday if staff?
  end

  def orders_package_abilities
    can [:index, :search], OrdersPackage if @api_user || staff?
  end

  def item_abilities
    if staff?
      can [:index, :show, :create, :update, :messages, :move_stockit_item_set,
        :designate_stockit_item_set, :dispatch_stockit_item_set, :update_designation_of_set], Item
    else
      can [:index, :show, :create], Item, Item.donor_items(user_id) do |item|
        item.offer.created_by_id == @user_id
      end
      can :update, Item, Item.donor_items(user_id) do |item|
        item.offer.created_by_id == @user_id && item.not_received_packages?
      end
    end
    can :destroy, Item, offer: { created_by_id: @user_id }
    can :destroy, Item if staff?
  end

  def image_abilities
    if staff?
      can [:index, :show, :create, :update, :destroy, :delete_cloudinary_image], Image
    else
      can [:index, :show, :create, :update, :destroy], Image, Image.donor_images(@user_id) do |record|
        record.imageable.offer.created_by_id == @user_id
      end
    end
    can :destroy, Image, imageable: { offer: { created_by_id: @user_id },
      state: ['draft', 'submitted', 'scheduled'] }
    can :destroy, Image, imageable: {
      state: ['draft', 'submitted', 'accepted', 'rejected', 'scheduled'] } if @reviewer
    can :destroy, Image if @supervisor
  end

  def message_abilities
    # Message (sender and admins, not user if private is true)
    if @supervisor
      can [:index, :show, :create, :update, :destroy], Message
    elsif @reviewer
      can [:index, :show, :create], Message
    else
      can [:index, :show, :create], Message, Message.donor_messages(@user_id) do |message|
        message.offer.created_by_id == @user_id && !message.is_private
      end
    end
    can [:mark_read], Message, id: @user.subscriptions.pluck(:message_id)
  end

  def offer_abilities
    can :create, Offer
    can [:index, :show, :update], Offer, created_by_id: @user_id,
      state: Offer.donor_valid_states
    can [:index, :show, :update], Offer if staff?

    can :destroy, Offer, created_by_id: @user_id, state: ['draft',
      'submitted', 'reviewed', 'scheduled', 'under_review', 'inactive']
    can [:complete_review, :close_offer, :finished, :destroy, :review, :mark_inactive, :merge_offer, :receive_offer], Offer if staff?
  end

  def package_abilities
    if staff?
      can [:index, :show, :create, :update, :destroy, :print_barcode,
        :search_stockit_items, :designate_stockit_item, :remove_from_set,
        :undesignate_stockit_item, :designate_partial_item, :update_partial_quantity_of_same_designation,:undesignate_partial_item, :dispatch_stockit_item, :move_stockit_item,
        :print_inventory_label, :undispatch_stockit_item,
        :stockit_item_details], Package
    else
      can [:index, :show, :create, :update], Package, Package.donor_packages(@user_id) do |record|
        record.item ? record.item.offer.created_by_id == @user_id : false
      end
    end
    can :create, Package if @api_user
    can :destroy, Package, item: { offer: { created_by_id: @user_id }, state: 'draft' }
    can :destroy, Package, item: { state: 'draft' } if @reviewer
  end

  def public_ability
    can :show_driver_details, Offer, {state: "scheduled", delivery: {gogovan_order: {status: ['pending', 'active']}}}

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

  def address_abilities
    # User address
    can [:create, :show], Address, addressable_type: "User", addressable_id: @user_id

    # Offer delivery address
    can [:create, :show, :destroy], Address, addressable_type: "Contact", addressable: { delivery: { offer_id: @user_offer_ids } }
    can [:create, :show, :destroy], Address, addressable_type: "Contact" if staff?
  end

  def schedule_abilities
    can [:create, :availableTimeSlots], Schedule
    can [:index, :show], Schedule, deliveries: { offer_id: @user_offer_ids }
    can [:index, :show], Schedule if staff?
  end

  def gogovan_order_abilities
    can [:calculate_price, :confirm_order, :destroy], GogovanOrder, delivery: { offer_id: @user_offer_ids }
    can [:calculate_price, :confirm_order, :destroy], GogovanOrder if staff?
  end

  def contact_abilities
    can :destroy, Contact, delivery: { offer_id: @user_offer_ids }
    can :destroy, Contact if staff?
    can :create, Contact
  end

  def taxonomies
    can :register, :device
    can [:index, :show], DonorCondition
    can [:index, :show], SubpackageType
    can [:index, :show], RejectionReason
    can [:index, :show], Permission
    can [:index, :show], CancellationReason
    can :create, PackageType if @api_user || staff?
    can [:create, :remove_number], InventoryNumber if @api_user || staff?
  end

  def user_abilities
    can [:show, :update], User, id: @user_id
    can [:index, :show, :update], User if staff?
    can :current_user_profile, User
  end

  def version_abilities
    can [:index, :show], Version, related_type: "Offer", related_id: @user_offer_ids
    can [:index, :show], Version, item_type: "Offer", item_id: @user_offer_ids
    can [:index, :show], Version if staff?
  end

  private

  def staff?
    @reviewer || @supervisor
  end
end
