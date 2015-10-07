class AddReceivingDetailsToOffers < ActiveRecord::Migration
  def change
    add_column :offers, :received_by_id, :integer
    add_column :offers, :start_receiving_at, :datetime
  end
end
