module Secured
  extend ActiveSupport::Concern

  class_methods do
    def lock_name
      "model:#{name}"
    end

    def locked
      with_advisory_lock(lock_name) { yield }
    end

    def secured_transaction
      locked do
        ActiveRecord::Base.transaction { yield }
      end
    end
  end

  def secured_transaction
    with_advisory_lock("#{self.class.name}:#{self.id}") do
      ActiveRecord::Base.transaction { yield }
    end
  end
end
