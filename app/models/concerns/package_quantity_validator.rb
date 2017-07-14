class PackageQuantityValidator < ActiveModel::Validator
  def validate(record)
    package = record.package
    if(package.present? && is_invalid_total_quantity?(record))
      record.errors.add(:quantity, "cannot be greater than package quantity")
    end
  end

  def is_invalid_total_quantity?(record)
    total = record.package.try(record.class.table_name).where.not(id: record.id).pluck(:quantity).sum + record.quantity
    total > record.package.received_quantity
  end
end
