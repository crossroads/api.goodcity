class AddDeliveredByToOffer < ActiveRecord::Migration
  def change
    add_column :offers, :delivered_by, :string, limit: 30
  end
end
