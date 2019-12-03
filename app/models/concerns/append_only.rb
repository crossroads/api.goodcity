module AppendOnly
  extend ActiveSupport::Concern

  included do
    before_destroy { raise ActiveRecord::ReadOnlyRecord }
  end

  def readonly?
    new_record? ? false : true
  end
end
