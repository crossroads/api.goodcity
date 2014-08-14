class Ability
  include CanCan::Ability

  #
  # Actions :index, :show, :create, :update, :destroy, :manage
  # See the wiki for details: https://github.com/CanCanCommunity/cancancan/wiki/Defining-Abilities
  #

  def initialize(user)

    if user.present?

      can(:manage, :all) if user.admin?

      # Offer
      can :create, Offer
      can [:index, :show, :update], Offer, created_by_id: user.id
      can [:index, :show, :update], Offer if user.reviewer? or user.supervisor?
      can :destroy, Offer, created_by_id: user.id, state: 'draft'
      can :destroy, Offer, state: 'draft' if user.reviewer?
      can :destroy, Offer if user.supervisor?

      # Item
      can [:index, :show, :create, :update], Item, offer: { created_by_id: user.id }
      can [:index, :show, :create, :update], Item if user.reviewer? or user.supervisor?
      can :destroy, Item, offer: { created_by_id: user.id }, state: 'draft'
      can :destroy, Item, state: 'draft' if user.reviewer?
      can :destroy, Item if user.supervisor?

      # Package (same as item permissions
      can [:index, :show, :create, :update], Package, item: { offer: { created_by_id: user.id } }
      can [:index, :show, :create, :update], Package if user.reviewer? or user.supervisor?
      can :destroy, Package, item: { offer: { created_by_id: user.id }, state: 'draft' }
      can :destroy, Package, item: { state: 'draft' } if user.reviewer?
      can :destroy, Package if user.supervisor?

      # Image
      # Message

      # User
      can [:show, :update], User, id: user.id
      can [:index, :show, :update], User if user.reviewer? or user.supervisor?

      # Taxonomies
      can [:index, :show], DonorCondition
      can [:index, :show], ItemType
      can [:index, :show], RejectionReason

    end

    # Anonymous and all users
    can [:index, :show], District
    can [:index, :show], Territory

  end
end
