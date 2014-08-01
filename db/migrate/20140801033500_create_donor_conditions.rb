class CreateDonorConditions < ActiveRecord::Migration
  def change
    create_table :donor_conditions do |t|
      t.string :name_en
      t.string :name_zh_tw

      t.timestamps
    end

    remove_column :items, :donor_condition
    add_column    :items, :donor_condition_id, :integer
  end
end
