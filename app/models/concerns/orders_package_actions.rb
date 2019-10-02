module OrdersPackageActions
  extend ActiveSupport::Concern


  #
  # Enum of all available actions
  #
  module Actions
    class Action < Utils::Toggleable
      def initialize(name, &block)
        super(name)
        @block = block
      end

      def run(orders_package, opts = {})
        @block.call(orders_package, opts)
      end
    end

    CANCEL          = Action.new('cancel') { |op| op.cancel }
    DISPATCH        = Action.new('dispatch') { |op| op.dispatch_orders_package }
    UNDISPATCH      = Action.new('undispatch') { |op| op.undispatch_orders_package }
    REDESIGNATE     = Action.new('redesignate') { |op, opts| op.redesignate(opts[:order_id]) }
    EDIT_QUANTITY   = Action.new('edit_quantity') { |op, opts| op.edit_quantity(opts[:quantity]) }

    ALL_ACTIONS = [CANCEL, DISPATCH, UNDISPATCH, REDESIGNATE, EDIT_QUANTITY]
  end

  #
  # Returns a list of actions which can be run against the orders_package
  #
  def allowed_actions
    ActionResolver.resolve(self)
  end

  #
  # Returns true if it is possible to run the action
  #
  def can_exec_action(name)
    allowed_actions
      .select { |act| act[:enabled] }
      .map { |act| act[:name] }
      .include? name.to_s
  end

  #
  # Tries to run the action
  #
  def exec_action(name, opts = {})
    unless can_exec_action(name)
      raise ArgumentError.new(I18n.t('orders_package.action_disabled', name: name))
    end

    action = Actions::ALL_ACTIONS.find { |act| act.name.to_s == name.to_s }
    action.run(self, opts)
  end

  private

  #
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
        when PACKAGE_CANCELLED then [
          Actions::REDESIGNATE.if(package_has_quantity?)
        ]
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

    def package_has_quantity?
      @model.package.in_hand_quantity.positive?
    end

    def can_decrease_qty?
      @model.quantity > 1
    end

    def can_increae_qty?
      package_has_quantity?
    end

    def editable_qty?
      can_decrease_qty? || can_increae_qty?
    end
  end
end
