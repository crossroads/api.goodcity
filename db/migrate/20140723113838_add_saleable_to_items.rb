class AddSaleableToItems < ActiveRecord::Migration
  def change
    add_column :items, :saleable, :boolean, default: false
  end
end
