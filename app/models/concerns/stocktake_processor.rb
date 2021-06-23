module StocktakeProcessor
  extend ActiveSupport::Concern

  included do
    private_class_method :apply_package_revision
    private_class_method :persist_errors
    private_class_method :serialize_exception
  end

  class_methods do
    #
    # Iterates through the stocktake revisions and applies changes
    #
    # @param [Stocktake] stocktake the stocktake instance to process
    #
    # @return [boolean]
    #
    def process_stocktake(stocktake)
      errors = {}

      raise Goodcity::InvalidStateError.new(I18n.t('stocktakes.invalid_state')) unless stocktake.open?
      raise Goodcity::InvalidStateError.new(I18n.t('stocktakes.dirty_revisions')) if stocktake.revisions.where(dirty: true).count.positive?

      Stocktake.without_auto_counters do
        PackagesInventory.secured_transaction do
          PushService.paused do
            stocktake.revisions.find_each do |revision|
              next unless revision.pending?

              error = apply_package_revision(revision)
              errors[revision.id] = error if error.present?
            end
          end

          raise ActiveRecord::Rollback if errors.length.positive?

          stocktake.revisions.update_all(state: 'processed')
          stocktake.close
        end

        persist_errors(stocktake, errors)

        stocktake.compute_counters! # Manually trigger recount at the end

        errors.values
      end
    end

    def serialize_exception(e, revision)
      message = e.message
      message = message.gsub(/^Validation failed:/, '') if e.is_a?(ActiveRecord::RecordInvalid)
      { revision: revision, message: message }
    end

    def persist_errors(stocktake, errors)
      ActiveRecord::Base.transaction do
        stocktake.revisions.each do |rev|
          message = errors[rev.id].present? ? errors[rev.id][:message] : ''
          rev.reload.update(warning: message)
        end
      end
    end

    def apply_package_revision(stocktake_revision)
      stocktake         = stocktake_revision.stocktake
      location          = stocktake.location
      package           = stocktake_revision.package
      recorded_quantity = PackagesInventory::Computer.package_quantity(package, location: location)
      delta             = stocktake_revision.quantity - recorded_quantity

      return if delta.zero?

      begin
        Package::Operations.register_quantity_change(package,
          quantity:     delta,
          location:     location,
          action:       delta.positive? ? PackagesInventory::Actions::GAIN : PackagesInventory::Actions::LOSS,
          description:  stocktake.name,
          source:       stocktake
        )

        stocktake_revision.update!(processed_delta: delta)
      rescue Goodcity::BaseError, ActiveRecord::RecordInvalid => e
        return serialize_exception(e, stocktake_revision)
      end

      return nil
    end
  end
end
