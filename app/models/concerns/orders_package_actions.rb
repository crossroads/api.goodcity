module OrdersPackageActions
  extend ActiveSupport::Concern

  #
  # Enum of all available actions
  #
  module Actions
    Toggleable = Utils::Toggleable

    REDESIGNATE     = Toggleable.new('redesignate')
    EDIT_QUANTITY   = Toggleable.new('edit_quantity')
    CANCEL          = Toggleable.new('cancel')
    DISPATCH        = Toggleable.new('dispatch')
    UNDISPATCH      = Toggleable.new('undispatch')
  end

  #
  # Returns a list of actions which can be run against the orders_package
  #
  def allowed_actions
    ActionResolver.resolve(self)
  end

  private

  # Small helper class that resolves the available actions
  # of an orders_package
  #
  # @example
  #   actions = ActionResolver.resolve(orders_package)
  #   puts(actions)  # => [{ name: 'cancel', enabled: true }, ... ]
  #
  #
  class ActionResolver

    def initialize(orders_package)
      @model = orders_package
    end

    def self.resolve(orders_package)
      ActionResolver.new(orders_package).resolve
    end

    def resolve
      case @model
        when ORDER_FINISHED then []
        when PACKAGE_CANCELLED then [ Actions::REDESIGNATE.on ]
        when PACKAGE_DESIGNATED then [
          Actions::EDIT_QUANTITY.if(editable_qty?),
          Actions::CANCEL.on,
          Actions::DISPATCH.on
        ]
        when PACKAGE_DISPATCHED then [ Actions::UNDISPATCH.on ]
        else [] # default
      end
    end

    private

    ORDER_FINISHED = -> (model) { Order::INACTIVE_STATES.include?(model.order.state) }
    PACKAGE_CANCELLED = -> (model) { model.cancelled? }
    PACKAGE_DESIGNATED = -> (model) { model.designated? }
    PACKAGE_DISPATCHED = -> (model) { model.dispatched? }

    def can_decrease_qty?
      @model.quantity > 1
    end

    def can_increae_qty?
      @model.package.quantity.positive?
    end

    def editable_qty?
      can_decrease_qty? || can_increae_qty?
    end
  end
end
