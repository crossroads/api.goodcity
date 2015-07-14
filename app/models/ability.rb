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

      can(:manage, :all) if admin

      # Address
      can [:create, :show], Address

      # Contact
      can [:create, :destroy], Contact

      # Delivery
      can [:create, :show, :update, :destroy, :confirm_delivery], Delivery

      # Item
      can [:index, :show, :create, :update], Item, offer: { created_by_id: user_id }
      can [:index, :show, :create, :update], Item if reviewer || supervisor
      can :destroy, Item, offer: { created_by_id: user_id }
      can :destroy, Item if reviewer || supervisor

      #Version
      can :index, Version, related_type: "Offer", related_id: user.offers.pluck(:id)
      can :index, Version, item_type: "Offer", item_id: user.offers.pluck(:id)
      can :index, Version if reviewer || supervisor

      # Image (same as item permissions)
      can [:index, :show, :create, :update], Image, item: { offer:
        { created_by_id: user_id } }
      can [:index, :show, :create, :update], Image if reviewer || supervisor
      can :destroy, Image, item: { offer: { created_by_id: user_id },
        state: ['draft', 'submitted', 'scheduled'] }
      can :destroy, Image, item: {
        state: ['draft', 'submitted', 'accepted', 'rejected', 'scheduled'] } if reviewer
      can :destroy, Image if supervisor

      # Message (sender and admins, not user if private is true)
      can [:index, :show, :create, :update, :destroy], Message if supervisor
      can [:index, :show, :create], Message if reviewer
      can [:index, :show, :create], Message, offer: {
        created_by_id: user_id }, is_private: false
      can [:mark_read], Message, id: user.subscriptions.pluck(:message_id)

      # Offer
      can :create, Offer
      can [:index, :show, :update], Offer, created_by_id: user_id,
        state: Offer.donor_valid_states
      can [:index, :show, :update], Offer if reviewer || supervisor
      can :destroy, Offer, created_by_id: user_id, state: ['draft',
        'submitted', 'reviewed', 'scheduled']
      can :destroy, Offer, state: ['draft', 'under_review',
        'submitted', 'scheduled'] if reviewer
      can :destroy, Offer if supervisor
      can :review, Offer if reviewer || supervisor
      can [:complete_review, :close_offer, :finished], Offer if reviewer || supervisor

      # Package (same as item permissions)
      can [:index, :show, :create, :update], Package, item: { offer:
        { created_by_id: user_id } }
      can [:index, :show, :create, :update, :destroy], Package if reviewer || supervisor
      can :destroy, Package, item: { offer: { created_by_id: user_id }, state: 'draft' }
      can :destroy, Package, item: { state: 'draft' } if reviewer


      # Schedule
      can :create, Schedule

      # GogovanOrder
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
    can [:browse], Item

    can [:index, :show], District
    can [:index, :show], Territory
    can [:index, :show, :availableTimeSlots], Schedule
    can :available_dates, Holiday
    can :index, Timeslot
    can :index, GogovanTransport
    can :index, CrossroadsTransport
    can :ggv_order_offer, Offer
  end
end
