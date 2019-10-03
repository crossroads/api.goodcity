class AddAllowPiecesToPackageTypes < ActiveRecord::Migration
  def change
    add_column :package_types, :allow_pieces, :boolean, default: false
  end
end
