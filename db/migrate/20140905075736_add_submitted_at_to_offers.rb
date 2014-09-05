class AddSubmittedAtToOffers < ActiveRecord::Migration
  def change
    add_column :offers, :submitted_at, :datetime
  end
end
