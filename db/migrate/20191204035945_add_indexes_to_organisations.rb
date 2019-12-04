class AddIndexesToOrganisations < ActiveRecord::Migration
  def change
    add_index :organisations, :name_en
    add_index :organisations, :name_zh_tw
  end
end
