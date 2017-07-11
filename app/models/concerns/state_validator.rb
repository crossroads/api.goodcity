class StateValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    if is_invalid?(record, value)
      record.errors.add(:state, 'same state')
    end
  end

  def is_invalid?(record, value)
    received_quantity = record.package.received_quantity
    record.state_was == value && received_quantity == record.quantity && record.quantity_was == received_quantity
  end
end
