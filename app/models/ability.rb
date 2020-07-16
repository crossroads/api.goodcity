class Ability
  include CanCan::Ability

  # Actions :index, :show, :create, :update, :destroy, :manage
  # See the wiki for details: https://github.com/CanCanCommunity/cancancan/wiki/Defining-Abilities

  attr_accessor :user, :user_id, :admin, :supervisor, :reviewer, :user_offer_ids, :user_permissions

  PERMISSION_NAMES = %w[
    can_manage_items can_manage_goodcity_requests
    can_manage_packages can_manage_offers can_manage_organisations_users
    can_search_browse_packages can_manage_deliveries can_manage_delivery_address
    can_manage_delivery_address can_manage_orders can_manage_order_transport
    can_manage_holidays can_manage_orders_packages can_manage_images
    can_add_package_types can_add_or_remove_inventory_number
    can_check_organisations can_access_packages_locations can_create_donor
    can_destroy_image_for_imageable_states can_destroy_contacts
    can_read_or_modify_user can_handle_gogovan_order
    can_read_schedule can_destroy_image can_destroy_package_with_specific_states
    can_manage_locations can_read_versions can_create_goodcity_requests
    can_manage_settings can_manage_companies can_manage_package_detail
    can_access_printers can_remove_offers_packages
    can_access_orders_process_checklists can_mention_users
    can_manage_order_messages can_manage_offer_messages can_disable_user
    can_manage_package_messages
  ].freeze

  PERMISSION_NAMES.each do |permission_name|
    define_method "#{permission_name}?" do
      @user_permissions.include?(permission_name)
    end
  end

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
      @user_permissions ||= @user.user_permissions_names

      can(:manage, :all) if admin
      define_abilities
    end
  end

  def define_abilities
    address_abilities
    appointment_slot_abilities
    beneficiary_abilities
    contact_abilities
    deliveries_abilities
    gogovan_order_abilities
    goodcity_request_abilitites
    goodcity_setting_abilitites
    holiday_abilities
    image_abilities
    item_abilities
    offer_abilities
    order_abilities
    message_abilities
    orders_package_abilities
    order_transport_abilities
    orders_process_checklists_abilities
    organisations_abilities
    organisations_users_abilities
    requested_packages_abilities
    package_abilities
    package_type_abilities
    packages_locations_abilities
    schedule_abilities
    stockit_abilities
    stockit_contact_abilities
    stockit_organisation_abilities
    stockit_local_order_abilities
    taxonomies
    user_abilities
    version_abilities
    company_abilities
    computer_abilities
    computer_accessory_abilities
    electrical_abilities
    medical_abilities
    printer_abilities
    offers_package_abilities
  end

  def printer_abilities
    can :index, Printer if can_access_printers?
  end

  def address_abilities
    # User address
    can [:create, :show], Address, addressable_type: "User", addressable_id: @user_id

    # Offer delivery address
    can [:create, :show, :destroy], Address, addressable_type: "Contact", addressable: { delivery: { offer_id: @user_offer_ids } }
    can [:create, :show, :destroy], Address, addressable_type: "Contact" if can_manage_delivery_address?
  end

  def appointment_slot_abilities
    return unless can_manage_settings?
    can [:create, :index, :destroy, :update], AppointmentSlotPreset
    can [:create, :index, :destroy, :update, :calendar], AppointmentSlot
  end

  def beneficiary_abilities
    can :create, Beneficiary
    can %i[index show update destroy], Beneficiary, created_by_id: @user_id
    can %i[show update destroy], Beneficiary, order: { submitted_by_id: @user_id }
    can %i[show update destroy], Beneficiary, order: { created_by_id: @user_id }
    if can_manage_orders? || @api_user
      can [:create, :index, :show, :update, :destroy], Beneficiary
    end
  end

  def computer_abilities
    can [:create, :index, :show, :update, :destroy], Computer if can_manage_package_detail?
  end

  def computer_accessory_abilities
    can [:create, :index, :show, :update, :destroy], ComputerAccessory if can_manage_package_detail?
  end

  def electrical_abilities
    can [:create, :index, :show, :update, :destroy], Electrical if can_manage_package_detail?
  end

  def medical_abilities
    can [:create, :index, :show, :update, :destroy], Medical if can_manage_package_detail?
  end

  def goodcity_request_abilitites
    can :create, GoodcityRequest if can_create_goodcity_requests?
    if can_manage_goodcity_requests?
      can [:index, :show, :create, :destroy, :update], GoodcityRequest
    else
      can [:index, :show, :update, :destroy], GoodcityRequest, GoodcityRequest.of_user(@user_id) do |r|
        r.created_by_id == @user_id || r.order.created_by_id == @user_id
      end
    end
  end

  def goodcity_setting_abilitites
    can :index, GoodcitySetting
    can [:create, :update, :destroy], GoodcitySetting if can_manage_settings?
  end

  def contact_abilities
    can :destroy, Contact, delivery: { offer_id: @user_offer_ids }
    can :destroy, Contact if can_destroy_contacts?
    can :create, Contact
  end

  def deliveries_abilities
    can [:create], Delivery
    if can_manage_deliveries?
      can [:index, :show, :update, :destroy, :confirm_delivery], Delivery
    else
      can [:show, :update, :destroy, :confirm_delivery], Delivery, offer_id: @user_offer_ids
    end
  end

  def gogovan_order_abilities
    can [:calculate_price, :confirm_order, :destroy], GogovanOrder, delivery: { offer_id: @user_offer_ids }
    can [:calculate_price, :confirm_order, :destroy], GogovanOrder if can_handle_gogovan_order?
  end

  def holiday_abilities
    can [:available_dates], Holiday
    if can_manage_holidays?
      can [:index, :destroy, :create, :update], Holiday
    end
  end

  def image_abilities
    if can_manage_images?
      can [:index, :show, :create, :update, :destroy, :delete_cloudinary_image], Image
    else
      can [:index, :show, :create, :update, :destroy], Image, Image.donor_images(@user_id) do |record|
        record.imageable.offer.created_by_id == @user_id
      end
      can [:show], Image, { imageable_type: "Package", imageable: { order: { created_by_id: @user_id } } }
    end
    can :destroy, Image, imageable: { offer: { created_by_id: @user_id },
      state: ['draft', 'submitted', 'scheduled'] }
    can :destroy, Image, imageable: {
      state: ['draft', 'submitted', 'accepted', 'rejected', 'scheduled'] } if can_destroy_image_for_imageable_states?
    can :destroy, Image if can_destroy_image?
  end

  def item_abilities
    if can_manage_items?
      can [:index, :show, :create, :update, :messages, :destroy], Item
    else
      can [:index, :show, :create], Item, Item.donor_items(user_id) do |item|
        item.offer.created_by_id == @user_id
      end
      can :update, Item, Item.donor_items(user_id) do |item|
        item.offer.created_by_id == @user_id && item.not_received_packages?
      end
    end
    can :destroy, Item, offer: { created_by_id: @user_id }
  end

  def message_abilities
    can %i[index show create], Message, messageable_type: 'Offer' if can_manage_offer_messages?
    can %i[index show create], Message, messageable_type: 'Item' if can_manage_offer_messages?
    can %i[index show create], Message, messageable_type: 'Order' if can_manage_order_messages?
    can [:manage], Message, messageable_type: 'Package' if can_manage_package_messages?
    can %i[index show mark_read mark_all_read], Message, id: @user.subscriptions.pluck(:message_id), is_private: false

    # Normal users can create non private messages on objects they own
    can :create, Message do |message|
      @user_id != nil && !message.is_private && message.related_object&.created_by_id == @user_id
    end
  end

  def offer_abilities
    can :create, Offer
    can [:index, :show, :update], Offer, created_by_id: @user_id,
      state: Offer.donor_valid_states

    can :destroy, Offer, created_by_id: @user_id, state: ['draft',
      'submitted', 'reviewed', 'scheduled', 'under_review', 'inactive']

    if can_manage_offers?
      can [:index, :show, :update, :complete_review, :close_offer, :search,
        :destroy, :review, :mark_inactive, :merge_offer, :receive_offer, :summary], Offer
    end
  end

  def offers_package_abilities
    if can_remove_offers_packages?
      can [:destroy], OffersPackage
    end
  end

  def order_abilities
    can :create, Order
    can %i[index show transition], Order, created_by_id: @user_id
    can %i[update destroy], Order, created_by_id: @user_id, state: %w[draft submitted processing awaiting_dispatch]
    if can_manage_orders? || @api_user
      can %i[create index show transition summary], Order
      can %i[update destroy], Order, state: %w[draft submitted processing awaiting_dispatch]
      can :index, ProcessChecklist
    end
  end

  def orders_package_abilities
    if can_manage_orders_packages? || @api_user
      can [:index, :search, :show, :destroy, :exec_action], OrdersPackage
    else
      can [:index, :search, :show, :destroy, :exec_action], OrdersPackage, order: { created_by_id: @user_id }
      can [:index, :search, :show, :destroy, :exec_action], OrdersPackage, order: { submitted_by_id: @user_id }
    end
  end

  def order_transport_abilities
    can :create, OrderTransport
    if can_manage_order_transport?
      can %i[create index show], OrderTransport
      can [:update], OrderTransport, order: { state: %w[draft submitted processing awaiting_dispatch] }
    else
      can [:index, :show], OrderTransport, OrderTransport.user_orders(@user_id) do |transport|
        transport.order.created_by_id == @user_id
      end

      can :update, OrderTransport, OrderTransport.user_orders(@user_id) do |transport|
        (%w[draft submitted processing awaiting_dispatch].include? transport.order.state) && (transport.order.created_by_id == @user_id)
      end
    end
  end

  def orders_process_checklists_abilities
    if can_access_orders_process_checklists?
      can [:index], OrdersProcessChecklist
    end
  end

  def organisations_abilities
    if can_check_organisations? || @api_user
      can [:index, :search, :show, :organisation_orders], Organisation
    end
  end

  def company_abilities
    if can_manage_companies? || @api_user
      can [:create, :index, :show, :update], Company
    end
  end

  def organisations_users_abilities
    if can_manage_organisations_users? || @api_user
      can [:create, :show, :index, :update], OrganisationsUser
    end
    can [:update], OrganisationsUser, user_id: @user_id
  end

  def requested_packages_abilities
    can [:create, :destroy, :index, :checkout], RequestedPackage, user_id: @user_id
  end

  def package_abilities
    if can_manage_packages?
      can %i[index show create update destroy print_barcode package_valuation
             search_stockit_items remove_from_set designate register_quantity_change
             mark_missing move print_inventory_label stockit_item_details
             split_package add_remove_item contained_packages parent_containers
             fetch_added_quantity], Package
      can %i[show create update destroy], PackageSet
      can %i[index], Restriction
      can %i[index], PackagesInventory
    end
    can [:show], Package,  orders_packages: { order: { created_by_id: @user_id }}
    can [:show], Package,  requested_packages: { user_id: @user_id }
    can :create, Package if @api_user
    can :destroy, Package, item: { offer: { created_by_id: @user_id }, state: 'draft' }
    can :destroy, Package, item: { state: 'draft' } if can_destroy_package_with_specific_states?
  end

  def package_type_abilities
    if can_add_package_types? || @api_user
      can :create, PackageType
    end
  end

  def public_ability
    can :show_driver_details, Offer, { state: "scheduled", delivery: {gogovan_order: { status: ['pending', 'active'] } } }

    # Anonymous and all users
    can [:index, :show], PackageCategory
    can [:index, :show], PackageType
    can [:index, :show], Package, { allow_web_publish: true}
    can :index, DonorCondition
    can [:index, :show], District
    can [:index, :show], IdentityType
    can [:index, :show], Territory
    can :index, Timeslot
    can :index, Country
    can :index, GogovanTransport
    can :index, CrossroadsTransport
    can :index, BookingType
    can :index, Purpose
    can :index, GoodcitySetting
    can :calendar, AppointmentSlot
  end

  def packages_locations_abilities
    if can_access_packages_locations? || @api_user
      can [:index, :show], PackagesLocation
    end
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

  def taxonomies
    can :register, :device
    can [:index, :show], DonorCondition
    can [:index, :show], SubpackageType
    can [:index, :show], RejectionReason
    can [:index, :show], Role
    can [:index, :show], Permission
    can [:index, :show], UserRole
    can [:index, :show], CancellationReason
    can [:names], Organisation
    can [:create, :show], OrganisationsUser

    if can_add_or_remove_inventory_number? || @api_user
      can [:create, :remove_number], InventoryNumber
    end
  end

  def schedule_abilities
    can [:create, :availableTimeSlots], Schedule
    can [:index, :show], Schedule, deliveries: { offer_id: @user_offer_ids }
    can [:index, :show], Schedule if can_read_schedule?
  end

  def stockit_abilities
    if can_manage_locations? || @api_user
      can [:index, :create, :destroy], Location
    end

    if @api_user
      can [:create, :index], Box
      can [:create, :index], Pallet
      can [:create, :index], Country
      can [:create, :index], StockitActivity
    end
  end

  def user_abilities
    can [:current_user_profile], User
    can %i[show update orders_count], User, id: @user_id
    can %i[index show update recent_users create], User if can_read_or_modify_user?
    can %i[create show], User if can_create_donor?
    can %i[mentionable_users], User if can_mention_users?
  end

  def version_abilities
    can [:index, :show], Version, related_type: "Offer", related_id: @user_offer_ids
    can [:index, :show], Version, item_type: "Offer", item_id: @user_offer_ids
    can [:index, :show], Version if can_read_versions?
  end
end
