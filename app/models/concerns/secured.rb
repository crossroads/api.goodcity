module Secured
  extend ActiveSupport::Concern

  class_methods do
    def lock_name(suffix = '')
      "model:#{name}:#{suffix}"
    end

    def locked(suffix = '')
      with_advisory_lock(lock_name(suffix)) { yield }
    end

    def secured_transaction(suffix = '')
      locked(suffix) do
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
