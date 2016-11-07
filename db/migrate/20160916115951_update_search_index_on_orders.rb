class UpdateSearchIndexOnOrders < ActiveRecord::Migration
  def up
    execute "DROP INDEX st_designations_code_idx;"

    unless index_exists?(:orders, :code, name: "orders_code_idx")
      execute "CREATE INDEX orders_code_idx ON orders USING gin (code gin_trgm_ops);"
    end
  end

  def down
    execute "DROP INDEX orders_code_idx;"
  end
end
