class AddIndexesToOrganisations < ActiveRecord::Migration[4.2]
  def change
    add_index :organisations, :name_en
    add_index :organisations, :name_zh_tw
  end
end
