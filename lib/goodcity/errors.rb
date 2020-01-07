module Goodcity
  class BaseError < StandardError; end

  class OperationsError < BaseError; end

  class UnprocessedError < OperationsError
    def initialize
      super(I18n.t('operations.dispatch.unprocessed_order'))
    end
  end

  class AlreadyDispatchedError < OperationsError
    def initialize
      super(I18n.t('orders_package.already_dispatched'))
    end
  end

  class MissingQuantityError < OperationsError
    def initialize
      super(I18n.t('operations.move.not_enough_at_source'))
    end
  end

  class InvalidQuantityError < OperationsError
    def initialize(quantity)
      super(I18n.t('operations.generic.bad_quantity_param', quantity: quantity))
    end
  end

  class InsufficientQuantityError < OperationsError
    def initialize(quantity)
      super(I18n.t('operations.generic.insufficient_quantity', quantity: quantity))
    end
  end

  class InactiveOrderError < OperationsError
    def initialize(order)
      super(I18n.t('operations.generic.inactive_order', code: order.code))
    end
  end

  class NotInventorizedError < OperationsError
    def initialize()
      super(I18n.t('operations.generic.not_inventorized'))
    end
  end

  class MissingQuantityforDispatchError < OperationsError
    def initialize
      super(I18n.t('operations.dispatch.missing_quantity_for_dispatch'))
    end
  end
end