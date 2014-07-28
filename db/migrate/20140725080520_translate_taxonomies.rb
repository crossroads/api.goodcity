class TranslateTaxonomies < ActiveRecord::Migration
  def change
    rename_column :item_types, :name, :name_en
    add_column    :item_types, :name_zh_tw, :string
    rename_column :districts, :name, :name_en
    rename_column :territories, :name, :name_en
    rename_column :rejection_reasons, :name, :name_en
    add_column    :rejection_reasons, :name_zh_tw, :string
  end
end
