class PackageService

  attr_reader :package, :params, :app_name, :request_from_stockit, :package_params

  def initialize(package, params, app_name, package_params)
    @package = package
    @params = params
    @app_name = app_name
    @package_params =  package_params
  end

  def new_package_object
    package_record
  end

  def updated_package_object
    package.detail = assign_detail if params["package"]["detail_type"].present?
    package.assign_attributes(package_params)
    package.received_quantity = package_params[:quantity] if package_params[:quantity]
    package.donor_condition_id = package_params[:donor_condition_id] if assign_donor_condition?
    package.request_from_admin = admin_app?
    packages_location_for_admin
    package
  end

  private

  def admin_app?
    app_name == ADMIN_APP
  end

  def add_favourite_image
    image = Image.find_by(id: params["package"]["favourite_image_id"])
    @package.images.build(favourite: true, angle: image.angle,
                          cloudinary_id: image.cloudinary_id) if image
    params["package"].delete("favourite_image_id")
  end

  def assign_detail
    PackageDetailBuilder.new(
      package_params,
      request_from_stockit?
    ).build_or_update_record
  end

  def assign_donor_condition?
    package_params[:donor_condition_id] && stock_app?
  end

  def assign_storage_type
    storage_type_name = params["package"]["storage_type"] || "Package"
    return unless %w[Box Pallet Package].include?(storage_type_name)

    StorageType.find_by(name: storage_type_name)
  end

  def assign_values_to_existing_or_new_package
    new_package_params = package_params
    GoodcitySync.request_from_stockit = true
    package = existing_package || Package.new()
    delete_params_quantity_if_all_quantity_designated(new_package_params)
    package.assign_attributes(new_package_params)
    package.received_quantity = received_quantity
    package.build_or_create_packages_location(location_id, "build")
    package.location_id = location_id
    package.state = "received"
    package.order_id = order_id
    package.inventory_number = inventory_number
    package.box_id = box_id
    package.pallet_id = pallet_id
    package
  end

  def box_id
    Box.find_by(stockit_id: package_params[:box_id]).try(:id)
  end

  def delete_params_quantity_if_all_quantity_designated(new_package_params)
    if new_package_params["quantity"].to_i == package.total_assigned_quantity
      new_package_params.delete("quantity")
    end
  end

  def existing_package
    if (stockit_id = package_params[:stockit_id])
      Package.find_by(stockit_id: stockit_id)
    end
  end

  def inventory_number
    remove_stockit_prefix(package.inventory_number)
  end

  def location_id
    if package_params[:location_id]
      Location.find_by(stockit_id: package_params[:location_id]).try(:id)
    end
  end

  def offer_id
    package.try(:item).try(:offer_id)
  end

  def order_id
    if package_params[:order_id]
      Order.accessible_by(current_ability).find_by(stockit_id: package_params[:order_id]).try(:id)
    end
  end

  def package_record
    if stock_app?
      package.donor_condition_id = package_params[:donor_condition_id] if assign_donor_condition?
      package.inventory_number = inventory_number
    elsif inventory_number
      assign_values_to_existing_or_new_package
    else
      package.assign_attributes(package_params)
    end
    package.storage_type = assign_storage_type
    package.detail = assign_detail if params["package"]["detail_type"].present?
    package.received_quantity ||= received_quantity
    add_favourite_image if params["package"]["favourite_image_id"]
    package.offer_id = offer_id
    package.inventory_number = inventory_number
    package
  end

  def packages_location_for_admin
    if admin_app? && params[:package][:location_id].present?
      package.build_or_create_packages_location(params[:package][:location_id], "create")
    end
  end

  def print_count
    params[:labels].to_i
  end

  def pallet_id
    Pallet.find_by(stockit_id: package_params[:pallet_id]).try(:id)
  end

  def remove_stockit_prefix(stockit_inventory_number)
    stockit_inventory_number.gsub(/^x/i, "") unless stockit_inventory_number.blank?
  end

  def received_quantity
    params[:package][:quantity].to_i
  end

  def request_from_stockit?
    app_name == STOCKIT_APP
  end

  def stock_app?
    app_name == STOCK_APP
  end

end
