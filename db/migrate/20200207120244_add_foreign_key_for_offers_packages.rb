class AddForeignKeyForOffersPackages < ActiveRecord::Migration
  def change
    add_foreign_key :offers_packages, :offers
    add_foreign_key :offers_packages, :packages
  end
end
