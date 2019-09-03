class StockitUpdateJob < ActiveJob::Base
  queue_as :stockit_updates

  def perform(package_id)
    package = Package.find_by(id: package_id)

    if package
      response = Stockit::ItemSync.update(package)

      # if Stockit can't find the item, it will create a new one and return the stockit_id
      # We need to update the stockit_id of the GoodCity package in this case.
      stockit_id = response['id']
      package.update_attribute(:stockit_id, stockit_id) unless stockit_id.blank?

      if response && (errors = response["errors"] || response[:errors])
        log_text = "Inventory: #{package.inventory_number} Package: #{package_id}"
        errors.each { |attribute, error| log_text += " #{attribute}: #{error}" }
        logger.error log_text
      end
    end
  end
end
