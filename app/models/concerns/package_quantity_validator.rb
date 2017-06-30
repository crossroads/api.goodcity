class PackageQuantityValidator < ActiveModel::Validator
  def validate(record)
    package = record.package
    if(package.present? && is_valid_total_quantity?(record))
      record.errors.add(:quantity, "cannot be greater than package quantity")
    end
  end

  def is_valid_total_quantity?(record)
    total = record.package.try(record.class.table_name).where.not(id: record.id).pluck(:quantity).sum + record.quantity
    total > get_package_quantity(record)
  end

  def get_package_quantity(record)
    if(record.class === "OrdersPackage")
      record.package.recived_quantity
    else #(record.class === "PackagesLocation")
      record.package.quantity
    end
  end
end
