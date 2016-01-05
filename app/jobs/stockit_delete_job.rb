class StockitDeleteJob < ActiveJob::Base
  queue_as :stockit_updates

  def perform(inventory_number)
    response = Stockit::Browse.new(inventory_number).remove_item

    if response && (errors = response["errors"] || response[:errors])
      log_text = "Inventory: #{inventory_number}"
      errors.each { |attribute, error| log_text += " #{attribute}: #{error}" }
      logger.error log_text
    end
  end
end
