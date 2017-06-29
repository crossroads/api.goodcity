class PackageQuantityValidator < ActiveModel::Validator
  def validate(record)
    if record.quantity <= record.received_quantity
      sibling_quantities(record, "packages_locations")
      sibling_quantities(record, "orders_packages")
    else
      record.errors.add(:quantity, "quantity cannot be greater than received_quantity")
    end
  end

  def sibling_quantities(record, attribute)
    attr  = record.send(attribute)
    quantity = record.received_quantity
    if (attr.present? && attr.pluck(:quantity).sum > quantity)
      record.errors.add(:package, attribute+" quantity cannot be greater than received_quantity")
    end
  end
end
