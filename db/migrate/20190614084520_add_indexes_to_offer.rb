class AddIndexesToOffer < ActiveRecord::Migration[4.2]
  def change
    add_index :offers, :state
  end
end
