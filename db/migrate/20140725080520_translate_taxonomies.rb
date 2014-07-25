class TranslateTaxonomies < ActiveRecord::Migration
  def change
    rename_column :item_types, :name, :name_en
    add_column    :item_types, :name_zh_tw, :string
  end
end
