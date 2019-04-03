class SameDesignationValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    if (record.order_id_was == value) && (record.state_was == "designated" and record.designated?)
      record.errors[attribute] << "already designated to this Package"
    end
  end
end
