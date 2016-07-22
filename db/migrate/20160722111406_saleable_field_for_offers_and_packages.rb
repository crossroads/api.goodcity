class SaleableFieldForOffersAndPackages < ActiveRecord::Migration
  def up
    add_column :offers, :saleable, :boolean, default: false
    add_column :packages, :saleable, :boolean, default: false

    Offer.reset_column_information
    Package.reset_column_information

    Rake::Task['goodcity:update_salable_for_offers_and_packages'].invoke

    remove_column :items, :saleable
  end

  def down
    add_column :items, :saleable, :boolean, default: false
    remove_column :offers, :saleable
    remove_column :packages, :saleable
  end
end
