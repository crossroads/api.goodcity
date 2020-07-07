module StocktakeProcessor
  extend ActiveSupport::Concern

  included do
    private_class_method :apply_package_revision
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
      errors = []

      raise Goodcity::InvalidStateError.new(I18n.t('stocktakes.invalid_state')) unless stocktake.open?
      raise Goodcity::InvalidStateError.new(I18n.t('stocktakes.dirty_revisions')) if stocktake.revisions.where(dirty: true).count.positive?

      PackagesInventory.secured_transaction do
        stocktake.revisions.each do |revision|
          next unless revision.pending?

          error = apply_package_revision(revision)
          errors << error if error.present?
        end

        raise ActiveRecord::Rollback if errors.length.positive?

        stocktake.revisions.update_all(state: 'processed')
        stocktake.close
      end
      
      persist_errors(errors) if errors.count.positive?

      errors
    end

    def persist_errors(errors)
      return unless errors.count.positive?

      ActiveRecord::Base.transaction do
        errors.each do |err|
          revision, message = err.values_at(:revision, :message)
          revision.update(warning: message)
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
      rescue Goodcity::BaseError => e
        return { revision: stocktake_revision, message: e.message }
      end

      return nil
    end
  end
end
