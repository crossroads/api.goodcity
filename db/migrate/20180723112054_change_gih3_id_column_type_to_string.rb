class ChangeGih3IdColumnTypeToString < ActiveRecord::Migration[4.2]
  def change
    change_column :organisations, :gih3_id, :string
  end
end
