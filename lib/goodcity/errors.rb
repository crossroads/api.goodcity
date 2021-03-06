module Goodcity
  # ----------------------------
  # Bases
  # ----------------------------

  class BaseError < StandardError
    attr_accessor :status

    def initialize(message, status: 422)
      message = message.join('. ') if message.is_a?(Array)
      super(message);
      @status = status;
    end

    def type
      self.class.name.split(':').last
    end

    def with_status(status)
      @status = status
      self
    end

    def as_json
      { error: message, type: type, status: status }
    end
  end

  class AccessError < BaseError; end

  class InvalidStateError < BaseError; end

  class OperationsError < BaseError; end

  class InventoryError < BaseError; end

  class ValidationError < BaseError; end

  class ExternalServiceError < BaseError; end

  class UnsupportedError < BaseError; end

  class UnknownError < BaseError; end

  # ----------------------------
  # Generic
  # ----------------------------

  class BadOrMissingRecord < BaseError
    def initialize(klass)
      super(I18n.t('errors.bad_or_missing_record', klass: klass.to_s))
    end
  end

  class ReadOnlyFieldError < BaseError
    def initialize(field)
      super(I18n.t('errors.read_only_field', field: field))
    end
  end

  class BadOrMissingField < BaseError
    def initialize(field)
      super(I18n.t('errors.bad_or_missing_field', field: field.to_s))
    end
  end

  class MissingParamError < BaseError
    def initialize(param)
      super(I18n.t('errors.missing_params', param: param))
    end
  end

  # ----------------------------
  # I18n based errors
  # ----------------------------

  def factory(base, default_translation_key, **opts)
    error_klass = Class.new(base) do
      define_method(:initialize) do |translation_key: default_translation_key, params: {}|
        msg = I18n.t(translation_key, { **params, default: translation_key })
        super(msg, **opts)
      end

      [
        :with_text,
        :with_translation
      ].each do |name|
        define_singleton_method(name) do |translation_key, params: {}|
          translation_key = default_translation_key if translation_key.blank?
          error_klass.new(translation_key: translation_key, params: params)
        end
      end
    end
  end

  module_function :factory

  InventorizedPackageError        = factory(BaseError, 'package.cannot_delete_inventorized')
  DisabledFeatureError            = factory(BaseError, 'goodcity.disabled_feature')
  DuplicateRecordError            = factory(BaseError, 'errors.duplicate_error', status: 409)
  InvalidParamsError              = factory(BaseError, 'errors.invalid_params', status: 422)
  NotFoundError                   = factory(BaseError, 'errors.not_found', status: 404)
  ForeignKeyMismatchError         = factory(BaseError, 'errors.foreign_key_mismatch_violation', status: 409)
  ForeignKeyDeletionError         = factory(BaseError, 'errors.foreign_key_delete_violation', status: 409)

  AccessDeniedError               = factory(AccessError, 'errors.forbidden', status: 403)
  UnauthorizedError               = factory(AccessError, 'warden.unauthorized', status: 401)
  InvalidCredentialsError         = factory(AccessError, 'organisations_user_builder.invalid.user', status: 401)
  InvalidPinError                 = factory(AccessError, 'auth.invalid_pin', status: 401)

  UnprocessedError                = factory(OperationsError, 'operations.dispatch.unprocessed_order')
  AlreadyDispatchedError          = factory(OperationsError, 'orders_package.quantity_already_dispatched')
  AlreadyDesignatedError          = factory(OperationsError, 'orders_package.already_designated')
  MissingQuantityError            = factory(OperationsError, 'operations.move.not_enough_at_source')
  NotInventorizedError            = factory(OperationsError, 'operations.generic.not_inventorized')
  AlreadyInventorizedError        = factory(OperationsError, 'operations.generic.already_inventorized')
  UninventoryError                = factory(OperationsError, 'operations.generic.uninventorize_error')
  MissingQuantityforDispatchError = factory(OperationsError, 'operations.dispatch.missing_quantity_for_dispatch')
  BadUndispatchQuantityError      = factory(OperationsError, 'operations.undispatch.missing_dispatched_quantity')
  ActionNotAllowedError           = factory(OperationsError, 'operations.generic.action_not_allowed')
  DetailTypeNotAllowed            = factory(BaseError, 'order.errors.invalid_detail_type', status: 422)

  # ----------------------------
  # Custom errors (unique params)
  # ----------------------------

  class ExpectedStateError < InvalidStateError
    def initialize(subject, state)
      super(I18n.t('errors.expected_state', subject: subject.class.to_s, state: state))
    end
  end

  class QuantityDesignatedError < OperationsError
    def initialize(orders)
      order_text = orders.count == 1 ? orders.first.code : "#{orders.count}x"
      super(I18n.t('operations.mark_lost.required_for_orders', orders: order_text))
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

  class MissingQuantityRequiredError < OperationsError
    def initialize(orders)
      order_text = orders.count == 1 ? orders.first.code : "#{orders.count}x"
      super(I18n.t('operations.mark_lost.required_for_orders', orders: order_text))
    end
  end
end
