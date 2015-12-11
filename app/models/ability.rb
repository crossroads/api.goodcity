class Ability
  include CanCan::Ability

  #
  # Actions :index, :show, :create, :update, :destroy, :manage
  # See the wiki for details: https://github.com/CanCanCommunity/cancancan/wiki/Defining-Abilities
  #

  def initialize(user)

    if user.present?

      # Cache repeated queries
      user_id = user.id
      admin = user.admin?
      supervisor = user.supervisor?
      reviewer = user.reviewer?
      user_offer_ids = user.offers.pluck(:id)

      can(:manage, :all) if admin

      # Address
      # TODO
      can [:create, :show], Address

      # Contact
      # TODO
      can [:create, :destroy], Contact

      # Delivery
      can [:create], Delivery
      if reviewer || supervisor
        can [:index, :show, :update, :destroy, :confirm_delivery], Delivery
      else
        can [:show, :update, :destroy, :confirm_delivery], Delivery, offer_id: user_offer_ids
      end

      # Item
      if reviewer || supervisor
        can [:index, :show, :create, :update, :messages], Item
      else
        can [:index, :show, :create], Item, Item.donor_items(user_id) do |item|
          item.offer.created_by_id == user_id
        end
        can :update, Item, Item.donor_items(user_id) do |item|
          item.offer.created_by_id == user_id && item.not_received_packages?
        end
      end
      can :destroy, Item, offer: { created_by_id: user_id }
      can :destroy, Item if reviewer || supervisor

      #Version
      can :index, Version, related_type: "Offer", related_id: user_offer_ids
      can :index, Version, item_type: "Offer", item_id: user_offer_ids
      can :index, Version if reviewer || supervisor

      # Image (same as item permissions)
      if reviewer || supervisor
        can [:index, :show, :create, :update], Image
      else
        can [:index, :show, :create, :update], Image, Image.donor_images(user_id) do |image|
          image.item.offer.created_by_id == user_id
        end
      end
      can :destroy, Image, item: { offer: { created_by_id: user_id },
        state: ['draft', 'submitted', 'scheduled'] }
      can :destroy, Image, item: {
        state: ['draft', 'submitted', 'accepted', 'rejected', 'scheduled'] } if reviewer
      can :destroy, Image if supervisor

      # Message (sender and admins, not user if private is true)
      if supervisor
        can [:index, :show, :create, :update, :destroy], Message
      elsif reviewer
        can [:index, :show, :create], Message
      else
        can [:index, :show, :create], Message, Message.donor_messages(user_id) do |message|
          message.offer.created_by_id == user_id && !message.is_private
        end
      end
      can [:mark_read], Message, id: user.subscriptions.pluck(:message_id)

      # Offer
      can :create, Offer
      can [:index, :show, :update], Offer, created_by_id: user_id,
        state: Offer.donor_valid_states
      can [:index, :show, :update], Offer if reviewer || supervisor

      can :destroy, Offer, created_by_id: user_id, state: ['draft',
        'submitted', 'reviewed', 'scheduled', 'under_review']
      can [:complete_review, :close_offer, :finished, :destroy, :review], Offer if reviewer || supervisor

      # Package (same as item permissions)
      if reviewer || supervisor
        can [:index, :show, :create, :update, :destroy], Package
      else
        can [:index, :show, :create, :update], Package, Package.donor_packages(user_id) do |package|
          package.item.offer.created_by_id == user_id
        end
      end
      can :destroy, Package, item: { offer: { created_by_id: user_id }, state: 'draft' }
      can :destroy, Package, item: { state: 'draft' } if reviewer

      # Schedule
      # TODO - only for offers owned by user
      can :create, Schedule

      # GogovanOrder
      # TODO - only for offers owned by user
      can [:calculate_price, :confirm_order, :destroy], GogovanOrder

      # User
      can [:show, :update], User, id: user_id
      can [:index, :show, :update], User if reviewer || supervisor
      can :current_user_profile, User

      # Auth
      can :register, :device

      # Taxonomies
      can [:index, :show], DonorCondition
      can [:index, :show], SubpackageType
      can [:index, :show], RejectionReason
      can [:index, :show], Permission

    end

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
end
