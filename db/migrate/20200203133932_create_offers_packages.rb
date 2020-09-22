class CreateOffersPackages < ActiveRecord::Migration[4.2]
  def change
    create_table :offers_packages do |t|
      t.integer :package_id
      t.integer :offer_id
    end
  end
end
