module Paranoid

  extend ActiveSupport::Concern

  included do
    acts_as_paranoid
  end

  # restore offer and its dependently destroyed associated records
  def recover
    restore(recursive: true)
  end

end
