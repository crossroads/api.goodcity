class StockitDeleteJob < ActiveJob::Base
  queue_as :stockit_updates

  def perform(inventory_number)
    response = Stockit::Browse.new(inventory_number).remove_item

    if response && (errors = response["errors"] || response[:errors])
      Stockit::Browse.log_errors("StockitDeleteJob", errors, inventory_number)
    end
  end
end
