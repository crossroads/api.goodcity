class PackageSplitter

  # Given a package with quantity 5, if you split 3 packages
  #   it will create 3 new packages each of qty 1 and the initial
  #   package will now have qty 2
  # Also ensures images are copied and returns false if package is not splittable

  def initialize(package, qty_to_split)
    @package = package
    @qty_to_split = qty_to_split.to_i
  end

  def splittable?
    @qty_to_split.positive? && 
      (@qty_to_split < @package.quantity) &&
      @package.inventory_number.present?
  end

  def split!
    return false unless splittable?
    deduct_qty_and_make_copies
  end

  private

  def deduct_qty_and_make_copies
    1..@qty_to_split.times do
      create_and_save_copy
    end
    @package.update(quantity: @package.quantity - @qty_to_split)
  end

  def create_and_save_copy
    copy = @package.dup
    copy.quantity = 1
    copy.received_quantity = 1
    copy.inventory_number = generate_q_inventory_number
    copy_and_save_images(copy) if copy.save
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
      copied_image.save
      copied_images << copied_image
    end
    copy.images << copied_images
  end

end