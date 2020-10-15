class AddAllowPiecesToPackageTypes < ActiveRecord::Migration[4.2]
  def change
    add_column :package_types, :allow_pieces, :boolean, default: false
  end
end
