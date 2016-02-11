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

      delivery_abilities
      item_abilities
      version_abilities
      image_abilities
      message_abilities
      offer_abilities
      package_abilities
      user_abilities
      location_abilities
      taxonomies
    end
  end

  def location_abilities
    can [:index, :create], Location if @api_user || staff?
  end

  def delivery_abilities
    can [:create], Delivery
    if staff?
      can [:index, :show, :update, :destroy, :confirm_delivery], Delivery
    else
      can [:show, :update, :destroy, :confirm_delivery], Delivery, offer_id: @user_offer_ids
    end
  end

  def item_abilities
    if staff?
      can [:index, :show, :create, :update, :messages], Item
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
      can [:index, :show, :create, :update], Image
    else
      can [:index, :show, :create, :update], Image, Image.donor_images(@user_id) do |record|
        record.item.offer.created_by_id == @user_id
      end
    end
    can :destroy, Image, item: { offer: { created_by_id: @user_id },
      state: ['draft', 'submitted', 'scheduled'] }
    can :destroy, Image, item: {
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
      'submitted', 'reviewed', 'scheduled', 'under_review']
    can [:complete_review, :close_offer, :finished, :destroy, :review, :mark_inactive, :merge_offer], Offer if staff?
  end

  def package_abilities
    if staff?
      can [:index, :show, :create, :update, :destroy, :print_barcode], Package
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
    can [:fetch_items], Item # for BrowseController
    can :index, DonorCondition
    can [:index, :show], District
    can [:index, :show], Territory
    can [:index, :show, :availableTimeSlots], Schedule
    can :available_dates, Holiday
    can :index, Timeslot
    can :index, GogovanTransport
    can :index, CrossroadsTransport
  end

  def taxonomies
    can :register, :device
    can [:index, :show], DonorCondition
    can [:index, :show], SubpackageType
    can [:index, :show], RejectionReason
    can [:index, :show], Permission
    can [:index, :show], CancellationReason

    # TODO
    can [:create, :show], Address
    can [:create, :destroy], Contact

    # Schedule
    # TODO - only for offers owned by user
    can :create, Schedule

    # GogovanOrder
    # TODO - only for offers owned by user
    can [:calculate_price, :confirm_order, :destroy], GogovanOrder
  end

  def user_abilities
    can [:show, :update], User, id: @user_id
    can [:index, :show, :update], User if staff?
    can :current_user_profile, User
  end

  def version_abilities
    can :index, Version, related_type: "Offer", related_id: @user_offer_ids
    can :index, Version, item_type: "Offer", item_id: @user_offer_ids
    can :index, Version if staff?
  end

  private

  def staff?
    @reviewer || @supervisor
  end
end
