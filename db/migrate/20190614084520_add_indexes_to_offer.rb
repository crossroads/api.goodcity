class AddIndexesToOffer < ActiveRecord::Migration
  def change
    add_index :offers, :state
  end
end
