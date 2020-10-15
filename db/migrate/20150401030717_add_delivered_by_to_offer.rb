class AddDeliveredByToOffer < ActiveRecord::Migration[4.2]
  def change
    add_column :offers, :delivered_by, :string, limit: 30
  end
end
