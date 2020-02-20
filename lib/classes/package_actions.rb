class PackageActions
  PACKAGE_ACTIONS = %w[loss process recycle trash].freeze

  def initialize(package, comment, quantity, user_id, location_id)
    @package = package
    @comment = comment
    @quantity = quantity
    @user_id = user_id
    @location_id = location_id
  end

  ["loss", "process", "recycle", "trash"].each do |task|
    define_method "#{task}" do
      register_change(task)
    end
  end

  private

  def register_change(task)
    unless quantity.positive?

    PackagesInventory.new(
      package: @package,
      source: @cause,
      action: task,
      location_id: @location_id,
      user_id: @user_id,
      quantity: quantity(task)
    )
  end

  def quantity(task)
  end

  def self.action_allowed?
    PACKAGE_ACTIONS.include?(task)
  end

  def invalid_quantity?
    @quantity > available_quantity_on_location(@location_id)
  end
end
