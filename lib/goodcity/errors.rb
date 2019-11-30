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
      super(I18n.t('operations.move.bad_quantity_param', quantity: quantity))
    end
  end
end