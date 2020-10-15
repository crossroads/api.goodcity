class AddClosedByToOffers < ActiveRecord::Migration[4.2]
  def change
    add_column :offers, :closed_by_id, :integer
  end
end
