class AddForeignKeyForOffersPackages < ActiveRecord::Migration[4.2]
  def change
    add_foreign_key :offers_packages, :offers
    add_foreign_key :offers_packages, :packages
  end
end
