class AddCountryIdToStockitDesignations < ActiveRecord::Migration
  def up
    add_column :stockit_designations, :country_id, :integer

    change_column :stockit_designations, :created_at, :datetime, null: true
  end

  def down
    remove_column :stockit_designations, :country_id
    change_column :stockit_designations, :created_at, :datetime, null: false
  end
end
