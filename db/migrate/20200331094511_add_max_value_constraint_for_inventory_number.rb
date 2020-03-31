class AddMaxValueConstraintForInventoryNumber < ActiveRecord::Migration
  def change
    reversible do |dir|
      dir.up do
        execute <<-SQL
          ALTER TABLE inventory_numbers
            ADD CONSTRAINT max_val
              CHECK (code between 0 AND 999999);
        SQL
      end
      dir.down do
        execute <<-SQL
          ALTER TABLE inventory_numbers
            DROP CONSTRAINT max_val
        SQL
      end
    end
  end
end
