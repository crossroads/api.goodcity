class CreateRequestedPackages < ActiveRecord::Migration
  def change
    create_table :requested_packages do |t|
      t.references :user, index: true
      t.references :package, index: true
      t.boolean :is_available
    end

    add_index :requested_packages, [:user_id, :package_id], :unique => true
    add_index :requested_packages, [:package_id, :user_id], :unique => true
  end
end
