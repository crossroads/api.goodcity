class Ability
  include CanCan::Ability

  # Actions :index, :show, :create, :update, :destroy, :manage
  # See the wiki for details: https://github.com/CanCanCommunity/cancancan/wiki/Defining-Abilities

  attr_accessor :user, :user_id, :user_offer_ids, :user_permissions

  PERMISSION_NAMES = %w[
    can_manage_items can_manage_goodcity_requests
    can_manage_packages can_manage_offers can_manage_organisations_users
    can_manage_deliveries can_manage_delivery_address
    can_manage_delivery_address can_manage_orders can_manage_order_transport
    can_manage_holidays can_manage_orders_packages can_manage_images
    can_add_package_types can_add_or_remove_inventory_number
    can_check_organisations can_access_packages_locations can_create_donor
    can_destroy_image_for_imageable_states can_destroy_contacts
    can_read_or_modify_user can_handle_gogovan_order
    can_read_schedule can_destroy_image can_destroy_package_with_specific_states
    can_manage_locations can_read_versions
    can_manage_settings can_manage_companies can_manage_package_detail
    can_access_printers can_remove_offers_packages can_access_orders_process_checklists
    can_mention_users can_read_users can_manage_printers can_update_my_printers
    can_manage_order_messages can_manage_offer_messages can_disable_user
    can_manage_stocktakes can_manage_stocktake_revisions
    can_manage_package_messages can_manage_organisations can_manage_user_roles
    can_manage_canned_response
  ].freeze

  PERMISSION_NAMES.each do |permission_name|
    define_method "#{permission_name}?" do
      self.user_permissions.include?(permission_name)
    end
  end

  def initialize(user)
    try(:public_ability)
    if user.present?
      @user = user
      @user_id = user.id
      try(:define_abilities)
    end
  end

  def user_permissions
    return [] unless @user.present?
    @user_permissions ||= @user.user_permissions_names
  end

  def user_organisations
    @user_organisations ||= @user.active_organisations.pluck(:id)
  end
end
