module DispatchAndUndispatch
  class UnDispatch < Base
    def initialize(package, order_id)
      super
    end

    def undispatch_package
      undispatch_stockit_item
    end
  end
end