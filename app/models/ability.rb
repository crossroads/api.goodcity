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
      can [:create, :show, :update, :destroy], Delivery

      # Item
      can [:index, :show, :create, :update], Item, offer: { created_by_id: user_id }
      can [:index, :show, :create, :update], Item if reviewer or supervisor
      can :destroy, Item, offer: { created_by_id: user_id }, state: 'draft'
      can :destroy, Item, state: 'draft', offer: { created_by_id: user_id }
      can :destroy, Item, state: 'draft' if reviewer
      can :destroy, Item if supervisor

      # Image (same as item permissions)
      can [:index, :show, :create, :update], Image, item: { offer: { created_by_id: user_id } }
      can [:index, :show, :create, :update], Image if reviewer or supervisor
      can :destroy, Image, item: { offer: { created_by_id: user_id }, state: ['draft', 'submitted', 'scheduled'] }
      can :destroy, Image, item: { state: ['draft', 'submitted', 'scheduled'] } if reviewer
      can :destroy, Image if supervisor

      # Message (sender and admins, not user if private is true)
      can [:index, :show, :create, :update, :destroy], Message if supervisor
      can [:index, :show, :create], Message if reviewer
      can [:index, :show, :create], Message, offer: { created_by_id: user_id }, is_private: false
      can [:mark_read], Message, id: user.subscriptions.pluck(:message_id)

      # Offer
      can :create, Offer
      can [:index, :show, :update], Offer, created_by_id: user_id
      can [:index, :show, :update], Offer if reviewer or supervisor
      can :destroy, Offer, created_by_id: user_id, state: ['draft', 'submitted', 'scheduled']
      can :destroy, Offer, state: 'draft' if reviewer
      can :destroy, Offer if supervisor
      can :review, Offer if reviewer or supervisor

      # Package (same as item permissions)
      can [:index, :show, :create, :update], Package, item: { offer: { created_by_id: user_id } }
      can [:index, :show, :create, :update], Package if reviewer or supervisor
      can :destroy, Package, item: { offer: { created_by_id: user_id }, state: 'draft' }
      can :destroy, Package, item: { state: 'draft' } if reviewer
      can :destroy, Package if supervisor

      # Schedule
      can :create, Schedule

      # GogovanOrder
      can [:calculate_price, :confirm_order, :destroy], GogovanOrder

      # User
      can [:show, :update], User, id: user_id
      can [:index, :show, :update], User if reviewer or supervisor
      can :current_user_profile, User

      # Taxonomies
      can [:index, :show], DonorCondition
      can [:index, :show], ItemType
      can [:index, :show], RejectionReason
      can [:index, :show], Permission

    end

    # Anonymous and all users
    can [:index, :show], District
    can [:index, :show], Territory
    can [:index, :show, :availableTimeSlots], Schedule
  end
end
