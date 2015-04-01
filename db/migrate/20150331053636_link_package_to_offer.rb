class LinkPackageToOffer < ActiveRecord::Migration
  def change
    add_column :packages, :offer_id, :integer, :null => false, :default => 0

    ActiveRecord::Base.connection.execute("update packages set offer_id = items.offer_id from items where packages.item_id = items.id")
  end
end
