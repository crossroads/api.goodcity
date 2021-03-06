class AddIndexesToPackage < ActiveRecord::Migration[4.2]

  def up
    execute "CREATE EXTENSION IF NOT EXISTS btree_gin;"
    execute "CREATE EXTENSION IF NOT EXISTS pg_trgm;"
    execute "CREATE INDEX index_packages_on_designation_name ON packages USING gin (designation_name gin_trgm_ops)"
    execute "CREATE INDEX index_packages_on_notes ON packages USING gin (notes gin_trgm_ops)"
    execute "CREATE INDEX index_packages_on_case_number ON packages USING gin (case_number gin_trgm_ops)"
    execute "CREATE INDEX index_packages_on_state ON packages USING gin (state gin_trgm_ops)"
    add_index :packages, :quantity, name: 'partial_index_quantity_greater_than_zero', where: "quantity > 0"
    add_index :packages, :allow_web_publish
  end

  def down
    remove_index :packages, :allow_web_publish
    remove_index :packages, name: "partial_index_quantity_greater_than_zero"
    execute "DROP INDEX index_packages_on_designation_name"
    execute "DROP INDEX index_packages_on_notes"
    execute "DROP INDEX index_packages_on_case_number"
    execute "DROP INDEX index_packages_on_state"
  end

end
