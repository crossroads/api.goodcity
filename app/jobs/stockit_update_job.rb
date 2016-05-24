class StockitUpdateJob < ActiveJob::Base
  queue_as :stockit_updates

  def perform(package_id)
    package = Package.find_by(id: package_id)

    if package
      response = Stockit::ItemSync.update(package)

      if response && (errors = response["errors"] || response[:errors])
        log_text = "Inventory: #{package.inventory_number} Package: #{package_id}"
        errors.each{ |attribute, error| log_text += " #{attribute}: #{error}" }
        logger.error log_text
      end
    end
  end
end
