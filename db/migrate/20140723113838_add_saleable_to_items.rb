class AddSaleableToItems < ActiveRecord::Migration[4.2]
  def change
    add_column :items, :saleable, :boolean, default: false
  end
end
