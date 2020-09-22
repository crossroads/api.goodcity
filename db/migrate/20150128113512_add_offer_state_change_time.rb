class AddOfferStateChangeTime < ActiveRecord::Migration[4.2]
  def change
    add_column :offers, :review_completed_at, :datetime
    add_column :offers, :received_at, :datetime
  end
end
