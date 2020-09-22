class AddSubmittedAtToOffers < ActiveRecord::Migration[4.2]
  def change
    add_column :offers, :submitted_at, :datetime
  end
end
