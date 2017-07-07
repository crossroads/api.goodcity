class StateValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    if record.state_was == value && record.package.received_quantity == record.quantity
      record.errors.add(:state, 'same state')
    end
  end
end
