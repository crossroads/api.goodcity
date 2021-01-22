class AddCounterCachesToStocktakes < ActiveRecord::Migration[5.2]
  def change
    add_column    :stocktakes, :counts ,    :integer, default: 0
    add_column    :stocktakes, :gains,      :integer, default: 0
    add_column    :stocktakes, :losses,     :integer, default: 0
    add_column    :stocktakes, :warnings,   :integer, default: 0
  end
end
