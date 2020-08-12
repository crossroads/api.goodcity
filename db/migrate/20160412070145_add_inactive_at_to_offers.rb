class AddInactiveAtToOffers < ActiveRecord::Migration[4.2]
  def change
    add_column :offers, :inactive_at, :datetime
  end
end
