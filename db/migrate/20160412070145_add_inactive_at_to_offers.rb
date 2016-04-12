class AddInactiveAtToOffers < ActiveRecord::Migration
  def change
    add_column :offers, :inactive_at, :datetime
  end
end
