class StateValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    received_quantity = record.package.received_quantity
    if record.state_was == value && received_quantity == record.quantity && record.quantity_was == received_quantity
      record.errors.add(:state, 'same state')
    end
  end
end
