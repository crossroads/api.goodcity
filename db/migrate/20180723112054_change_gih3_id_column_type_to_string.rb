class ChangeGih3IdColumnTypeToString < ActiveRecord::Migration
  def change
    change_column :organisations, :gih3_id, :string
  end
end
