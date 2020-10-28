class DeleteStockitBasedColumns < ActiveRecord::Migration[5.2]
  def change
    remove_column :computer_accessories, :stockit_id, :integer
    remove_column :computers, :stockit_id, :integer
    remove_column :countries, :stockit_id, :integer
    remove_column :electricals, :stockit_id, :integer
    remove_column :locations, :stockit_id, :integer
    remove_column :medicals, :stockit_id, :integer

    remove_column :orders, :stockit_id, :integer
    remove_column :orders, :stockit_contact_id, :integer
    remove_column :orders, :stockit_organisation_id, :integer
    remove_column :orders, :stockit_activity_id, :integer

    remove_column :package_types, :stockit_id, :integer

    remove_column :packages, :stockit_id, :integer
    remove_column :packages, :stockit_sent_on, :datetime
    remove_column :packages, :stockit_designated_on, :datetime
    remove_column :packages, :stockit_designated_by_id, :integer
    remove_column :packages, :stockit_sent_by_id, :integer
    remove_column :packages, :stockit_moved_on, :datetime
    remove_column :packages, :stockit_moved_by_id, :integer

    remove_column :pallets, :stockit_id, :integer
  end
end
