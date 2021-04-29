class AddAdditionalCountryFields < ActiveRecord::Migration[6.1]
  def change
    add_column :countries, :preferred_region, :string
    add_column :countries, :preferred_sub_region, :string
    add_column :countries, :m49, :integer
    add_column :countries, :iso_alpha2, :string
    add_column :countries, :iso_alpha3, :string
    add_column :countries, :ldc, :boolean, default: false
    add_column :countries, :lldc, :boolean, default: false
    add_column :countries, :sids, :boolean, default: false
    add_column :countries, :developing, :string
  end
end
