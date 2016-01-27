class StockitDeleteJob < ActiveJob::Base
  queue_as :stockit_updates

  def perform(inventory_number)
    response = Stockit::Item.delete(inventory_number)
    if response && (errors = response["errors"] || response[:errors])
      log_text = "Inventory number: #{inventory_number}"
      errors.each { |attribute, error| log_text += " #{attribute}: #{error}" }
      logger.error log_text
    end
  end

end
