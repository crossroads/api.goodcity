class AddCancelledAtToOffers < ActiveRecord::Migration[4.2]
  def change
    add_column :offers, :cancelled_at, :datetime
  end
end
