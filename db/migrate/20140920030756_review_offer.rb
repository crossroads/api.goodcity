class ReviewOffer < ActiveRecord::Migration[4.2]
  def change
    add_column :offers, :reviewed_by_id, :integer
    add_column :offers, :reviewed_at, :datetime
  end
end
