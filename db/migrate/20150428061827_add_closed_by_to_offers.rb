class AddClosedByToOffers < ActiveRecord::Migration
  def change
    add_column :offers, :closed_by_id, :integer
  end
end
