class AddNotNullConstraintToNotes < ActiveRecord::Migration[5.2]
  def change
    change_column_null :packages, :notes, false
  end
end
