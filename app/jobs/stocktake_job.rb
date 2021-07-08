class StocktakeJob < ActiveJob::Base
  queue_as :high

  def perform(stocktake_id)
    Stocktake.locked(stocktake_id) do
      stocktake = Stocktake.find(stocktake_id)

      if stocktake&.awaiting_process?
        Stocktake.process_stocktake(stocktake)
      end
    end
  end
end
