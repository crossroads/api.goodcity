class AddCancelledAtToOffers < ActiveRecord::Migration
  def change
    add_column :offers, :cancelled_at, :datetime
  end
end
