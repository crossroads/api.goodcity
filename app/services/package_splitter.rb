class PackageSplitter

  # Given a package with quantity 5, if you split a quantity of 3
  #   it will create 1 new package with a qty of 3 and the initial
  #   package will now have qty 2
  # Also ensures images are copied and raises an error if package is not splittable

  def initialize(package, qty_to_split)
    @package = package
    @qty_to_split = qty_to_split.to_i
  end

  def split!
    @package.inventory_lock do
      assert_splittable!
      deduct_quantity!
      create_and_save_copy!
    end
  end

  #
  # Exceptions
  #

  class SplitError < Goodcity::BaseError; end

  class InvalidSplitQuantityError < SplitError
    def initialize(qty)
      super(I18n.t('package.split_qty_error', qty: qty))
    end
  end

  class InvalidSplitLocationError < SplitError
    def initialize
      super(I18n.t('package.split_location_error'))
    end
  end

  private

  def assert_splittable!
    # raise Goodcity::DisabledFeatureError.new(params: { feature: 'split' })
    raise Goodcity::NotInventorizedError unless inventorized?
    raise InvalidSplitQuantityError.new(@package.available_quantity) unless splittable?
    raise InvalidSplitLocationError if @package.locations.count > 1
  end

  def inventorized?
    PackagesInventory.inventorized?(@package) && @package.inventory_number.present?
  end

  def splittable?
    @qty_to_split.positive? && @qty_to_split < @package.available_quantity
  end

  def source_location
    @package.locations.first
  end

  def deduct_quantity!
    Package::Operations.register_loss(@package, quantity: @qty_to_split, location: source_location)
    @package.update!(received_quantity: @package.received_quantity - @qty_to_split)
  end

  def create_and_save_copy!
    copy = @package.dup
    copy.received_quantity = @qty_to_split
    copy.inventory_number = generate_q_inventory_number
    copy.save!
    copy_and_save_images(copy)
    Package::Operations.inventorize(copy, source_location)
  end

  def generate_q_inventory_number
    inventory_number = @package.inventory_number.split("Q").first
    largest_q_number = Package.where("inventory_number LIKE ?", "#{inventory_number}Q%").order("ID DESC").limit(1)
    if largest_q_number.presence
      return  "#{inventory_number}Q#{largest_q_number.last.inventory_number.split('Q').last.to_i + 1}"
    else
      return "#{inventory_number}Q1"
    end
  end

  def copy_and_save_images(copy)
    copied_images = []
    @package.images.each do |image|
      copied_image = image.dup
      copied_image.imageable_id = copy.id
      copied_image.save!
      copied_images << copied_image
    end
    copy.images << copied_images
  end
end
